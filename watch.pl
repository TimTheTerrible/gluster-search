#!/usr/bin/perl -w

use strict;
use TimUtil;
use TimDB;

our $DB;

my $Period = 300;
my $Interval = 60;
my $Samples = $Period / $Interval;

# Main Program
{
    parse_args();

    our $dsn = {
        dbhost		=> "fijisearch.cfj0jnatftoe.us-east-1.rds.amazonaws.com",
        dbname		=> "fijisearch",
        dbuser		=> "fijisearch",
        dbpasswd	=> qw/Prk7jHheE9/,
        dbbackend	=> "Pg",
        dbport		=> 5432,
    };

    $DB = TimDB->new($dsn);

    my $starttotal = 0;
    my $count_total = 0;
    my $avgrows_total = 0;
    my $count_5min = 0;
    my $avgrows_5min = 0;
    my @counts = ();
    my $oldtotal = 0;

    while ( TRUE ) {

        debugprint(DEBUG_INFO, "Gathering statistics...");

        my $start_time = time();

        # Show the total files found and average files found per second...
        my $newtotal = 0;
        $DB->get_int(\$newtotal, "SELECT n_live_tup FROM pg_stat_user_tables WHERE relname='found_files'");

        # Set the starting mark...
        $starttotal = $newtotal if $starttotal == 0;
        $oldtotal = $newtotal if $oldtotal == 0;

        my $newrows = $newtotal - $oldtotal;
        debugprint(DEBUG_TRACE, "newrows = %s", $newrows);
        $avgrows_total = ( $newtotal - $starttotal ) / ++$count_total;

        push(@counts, $newrows);
        my $total_5min = 0;
        map( { $total_5min += $_; } @counts );
        $avgrows_5min = $total_5min / scalar(@counts);

        debugdump(DEBUG_DUMP, "before", \@counts);
        if ( scalar(@counts) > $Samples ) {
            @counts = @counts[-$Samples..-1];
        }
        debugdump(DEBUG_DUMP, "after", \@counts);

        # Show the percentage of directories remaining to be searched...
        my $searched = 0;
        $DB->get_int(\$searched, "SELECT count(*) FROM directories WHERE searched=true");

        my $total_remaining = 4325376 - $searched;
        my $percent_remaining = $searched / 4325376 * 100;

        # Show the number of searchers running...
        my $searchers = 0;
        $DB->get_int(\$searchers, "SELECT count(*) FROM directories WHERE searching=true");

        system("clear") unless $TimUtil::Debug & DEBUG_ALL == DEBUG_ALL;

        debugprint(DEBUG_INFO, "Data gathering took %s seconds", time() - $start_time);
        debugprint(DEBUG_INFO, "Files found: %s", $newtotal);
        debugprint(DEBUG_INFO, "Average files/second (overall): %d", $avgrows_total / $Interval);
        debugprint(DEBUG_INFO, "Average files/second (%s minutes): %d", $Period / 60, $avgrows_5min / $Interval);
        debugprint(DEBUG_INFO, "Directories searched: %s (%0.2f%%)", $searched, $percent_remaining);
        debugprint(DEBUG_INFO, "Searches running: %s", $searchers);

        $oldtotal = $newtotal;

        # All done; sleep for a bit...
        sleep($Interval);
    }
}

