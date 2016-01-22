#!/usr/bin/perl -w

use strict;
use TimUtil;
use TimDB;

our $DB;

our $Limit = TRUE;
our $DSN = "test";

our %ParamDefs = (
    limit	=> {
        name	=> "Limit",
        type	=> PARAMTYPE_BOOL,
        var	=> \$Limit,
        usage	=> "--limit|-l",
        comment	=> "Limit to ten iterations",
    },
    dsn	=> {
        name	=> "DSN",
        type	=> PARAMTYPE_STRING,
        var	=> \$DSN,
        usage	=> "--dsn|-d",
        comment	=> "The DSN to use",
    },
);

# Main Program
{
    my $returnval = E_NO_ERROR;

    register_params(\%ParamDefs);
    parse_args();

    our %DSNs = (
        prod	=> {
            dbhost	=> "fijisearch.cfj0jnatftoe.us-east-1.rds.amazonaws.com",
            dbname	=> "fijisearch",
            dbuser	=> "fijisearch",
            dbpasswd	=> qw/Prk7jHheE9/,
            dbbackend	=> "Pg",
            dbport	=> 5432,
        },
        test	=> {
            dbhost	=> "wotan.algernonsystems.com",
            dbname	=> "falkland1",
            dbuser	=> "postgres",
            dbpasswd	=> qw/@myPig0peN6/,
            dbbackend	=> "Pg",
            dbport	=> 5432,
        },
    );

    $DB = TimDB->new($DSNs{$DSN});

    debugprint(DEBUG_INFO, "Looking for dead searches in %s...", $DSN);

    my @searches = ();

    if ( ($returnval = $DB->get_hashref_array(\@searches, "SELECT * FROM directories WHERE searching=True")) == E_DB_NO_ERROR ) {
        debugprint(DEBUG_INFO, "Found %s dead searches", scalar(@searches));
        debugdump(DEBUG_DUMP, "searches", \@searches);

        my $count = 0;
        foreach my $search ( @searches ) {

            debugdump(DEBUG_DUMP, "search", \$search);
            debugprint(DEBUG_INFO, "Cleaning up %s:%s:%s...", $$search{host}, $$search{brick}, $$search{path});

            my $query = sprintf("DELETE FROM found_files WHERE host='%s' AND brick='%s' AND path LIKE '%s%%'", $$search{host}, $$search{brick}, $$search{path});
            debugprint(DEBUG_TRACE, "query = '%s'", $query);

            $returnval = $DB->dbexec($query) unless $TestOnly;

            if ( $returnval == E_DB_NO_ERROR ) {

                debugprint(DEBUG_INFO, "Deleted %s file records", $DB->{rows});

                $query = sprintf("UPDATE directories SET searching=False WHERE id=%s", $$search{id});
                debugprint(DEBUG_TRACE, "query = '%s'", $query);

                $returnval = $DB->dbexec($query) unless $TestOnly;
            }
            else {
                debugprint(DEBUG_ERROR, "Database error: %s", $DB->{errstr});
            }

            last if ++$count > 9 and $Limit;
        }
    }
    elsif ( $returnval = E_DB_NO_ROWS  ) {
        debugprint(DEBUG_WARN, "No dead searches found!");
    }
    else {
        debugprint(DEBUG_ERROR, "Database error: %s", $DB->{errstr});
    }
}

