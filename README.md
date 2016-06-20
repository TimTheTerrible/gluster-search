# gluster-search
A narrowly-tailored set of scripts for searching a vast gluster cluster suffering from severe split-brain

# Overview
These scripts were originally developed to search a group of very large Gluster clusters (both in terms of hardware footprint, as well as in raw capacity). Owing to some sort of undiagnosed problem with the underlying filesystems, the gluster clusters began to develop widespread split-brain. When the decision was made to decomission the clusters, it was decided that an effort would be made to search the bricks for valid copies of files that had gone missing as a result of the split-brain, storing all available information about the discovered files in a PostgreSQL database. After the surviving valid files had been migrated away from the rapidly deteriorating gluster clusters, it would be possible to go back and mine the search results for possible copies of missing files that could then be recovered. The following describes the basic assumptions made in the operation of these scripts. 

## Gluster Layout
The gluster clusters, each in a separate datacenter, consisted of many individual gluster servers, each equipped with three JBOD arrays, each of which was configured as a gluster brick. Each brick contained an identical directory structure, consisting of 256 directories at the root level (00 through FF), each of which directories contained 256 more directories, and then finally a third level of 256 directories, for a total of just under 17 million directories to search on each brick, or a hair over 50 million directories on each gluster server.  Simply doing a single-process "find" from the brick mount directory on even one server would take weeks to complete, so a plan was devised to break the work up among separate processes without taking on the heavyweight development challenge of threading the search somehow.

## Breaking up the Search
In order to break the search up into manageable chunks, the decision was made to stage a list of directories to be searched, and a method was developed to track which ones had been completely searched. The chosen solution was to create an additional table in the PostgreSQL database in which to track the progress of the search. The three-levels-deep nature of the directory tree made it a simple matter to generate the entire list of directories to be searched. It happened to be the case that searching one second-level directory (each of which contained 256 directories) was a conveniently-sized unit of work that could be completeted in a few tens of seconds to perhaps a minute or so, thus allowing for a fairly fine-grained workflow that could be conveniently stopped and started, allowing us to increase or decrease the number of workers on each gluster server in real time, without needing to throw away large blocks of partially completed work in order to maintain a provably complete search.

## Preparing the Database
The schema for the database table is defined in gluster_search.sql. Create the database as follows:

* psql -c "create role gluster_search with login password 'gluster_search'"
* psql -c "create database gluster_search with owner gluster_search"
* psql -W gluster_search gluster_search << gluster_search.sql


## Deploying the Scripts
The script "smart_search.pl", as well as its supporting libraries (TimUtil.pm and TimDB.pm) must be installed on each node. The other scripts can remain on the system from which the search is being conducted. It's important that the gluster nodes be able to reach the database server. If the specific network configuration doesn't allow direct connection, some fiddling around with "ssh -R" in start_search.sh should get it going.

## Starting the Search
Once the database has been created and populated with folder records, and the scripts and libraries have been correctly installed, create a file named "guster_hosts" and populate it with the names of the servers to be searched, one FQDN per line. Run the script "start_search.sh;" which will ssh to each host and start one search worker for each brick. Monitor the load, and if it looks like the server can handle it, run start_search.sh again (be careful of ssh tunnel tomfoolery if you elected to use that method) to start another search worker for each brick.

## Monitoring the Search
The script "watch.pl" can be run to monitor the progress of the search. Note that running this script puts considerable load on the database, so avoid the temptation to run it constantly.

## Stopping the Search
If it becomes necessary to stop the search, simply run "stop_search.sh;" it will ssh to each gluster server and kill off all running search workers. After doing this, always run "clear_dead_searches.pl" to reset the folder record for any partially-searched directories. This ensures that when the search is started up again it will begin from a known-good point.

## Using the Results
Once all directories have been searched, one can simply run simple queries against the found_files table to discover possible matches for missing files. If data about a large number of missing files is known, it can be imported into the missing_files table using the script "import_missing_files.pl," after which, more complex queries can be run to match missing_files against found_files.

## Scripts
gluster_search.sql - defines the schema for the PostgreSQL database that will hold the results of the search.
populate_folder_records.pl - creates the folder records that track the progress of the search.
clear_dead_searches.pl - cleans up interrupted partial searches. NEVER run this while and search workers are active!
start_search.sh - starts one search worker for each brick on each gluster server.
smart_search.pl - does the actual work of searching the gluster bricks and recording the stats of each found file.
stop_search.sh - stops all running search workers on all gluster servers.
watch.pl - queries the database and prints a report of the progress of the search.
import_missing.pl - import a CSV file describing the missing files.


