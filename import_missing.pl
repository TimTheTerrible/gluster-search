#!/usr/bin/perl -w

use strict;

use TimUtil;
use TimDB;

our $File = "";
our $Limit = TRUE;

our %ParamDefs = (
    file	=> {
        name	=> "File",
        type	=> PARAMTYPE_STRING,
        var	=> \$File,
        usage	=> "--file|-f",
        comment	=> "The name of a single dir file to import",
    },
    limit	=> {
        name	=> "Limit",
        type	=> PARAMTYPE_BOOL,
        var	=> \$Limit,
        usage	=> "--limit|-l",
        comment	=> "Limit to ten iterations",
    },
);

my $dsn = {
    dbhost	=> "localhost",
    dbname	=> "falkland2",
    dbuser	=> "postgres",
    dbpasswd	=> qw/@myPig0peN6/,
    dbbackend	=> "Pg",
    dbport	=> 5432,
};

our $DB = TimDB->new($dsn);

# Turns (foo,bar,baz) into "'foo','bar','baz'"
sub join_values
{
    my (@values) = @_;

    my $result = "";
    foreach my $value (@values) {
        $result .= "," unless $result eq "";
        $result .= "'" . $value . "'";
    }

    return $result;
}

sub import_dir
{
    my ($dirfile) = @_;

    debugprint(DEBUG_INFO, "dirfile: %s", $dirfile);

    open(DIRFILE, $dirfile);

    my $count = 0;
    while ( my $line = <DIRFILE> ) {
        chomp($line);
        debugprint(DEBUG_TRACE, "line ='%s'", $line);

        # Break out the parts of the line...
        # 1980200642001,4013,4013/4013_1980200642001_vs-50abc6eee4b0bdc7378739ae-782203300001.jpg,23547
        my $asset = {};
        ($$asset{asset_id},$$asset{pub_id},$$asset{bcfs_key},$$asset{size}) = split(',', $line);
        debugdump(DEBUG_DUMP, "asset", $asset);
        #next if $filename !~ /^[0-9]*_[0-9]*_.*/;

        # TODO: store the results in the database
        my $query_fmt = "INSERT INTO missing_files (id,asset_id,pub_id,bcfs_key,size) VALUES(nextval('missing_files_id_seq'),'%s','%s','%s','%s')";
        my $query = sprintf($query_fmt, $$asset{asset_id},$$asset{pub_id},$$asset{bcfs_key},$$asset{size});
        debugprint(DEBUG_TRACE, "query = '%s'", $query);

        $DB->dbexec($query) unless $TestOnly;

        last if $Limit and ++$count > 9;
    }

    close(DIRFILE);
}

# Main Program
{
    register_params(\%ParamDefs);
    parse_args();

    if ( $File ne "" ) {
        import_dir($File);
    }
    else {
        opendir(THISDIR, ".");

        while ( my $dirent = readdir(THISDIR) ) {

            chomp($dirent);
            debugprint(DEBUG_TRACE, "dirent = '%s'", $dirent);

            # Match files like "fiji_failed.nas4.js.out.fiji-falkland2.fal.csv"
            if ( $dirent =~ /fiji_failed.*falkland2\.fal\.csv/ ) {
                import_dir($dirent);
                last if $TestOnly;
            }
        }

        closedir(THISDIR);
    }
}
