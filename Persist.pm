#==============================================================================
#
# Package name: Persist
#
# Created by: Samuel Barton
#
# Project: Spider
#
# Description: This package represents the Persist class which is used for 
#              database interaction by WebCardReader.pl. 
#
#==============================================================================

package Persist;
use v5.22;
use DBI;
use DBD::Pg;

#==============================================================================
#
# Method name: connectToDB
#
# Parameters: none
#
# Returns: void
#
# Description: This method handles establishing the connection to the database.
#              This method is private.
#
#==============================================================================
sub __connectToDB
{
    my $driver = "Pg";
    my $database = "cardreader";
    my $host = "10.200.40.3";
    my $dsn = "dbi:$driver:database=$database;host=$host;port=5432";
    my $username = "postgres";
    my $password = "card_reader";

    my $dbh = DBI->connect($dsn, $username, $password) or 
    die $DBI::errstr;


    return $dbh;
}

#==============================================================================
#
# Method name: getInfo
#
# Parameters: id - the id number of the user's RFID card
#
# Returns: @info - the users name, password, and photo
#
# Description: This method retrieves the user's info from the database. This
#              method functions both as an authentication of the users id 
#              number, and the getter for their info.
#
#==============================================================================
sub getInfo
{
    # get an instance of this persist object
    my $self = shift;
    # get the id passed in as an argument
    my $id = shift;
    # get the database handle
    my $database = $self->{database};

    my $query = $database->prepare("SELECT name, password, photo ".
                                   "FROM user_list WHERE id=?");
    $query->execute($id);

    return $query->fetchrow_array; 
}

#==============================================================================
#
# Method name: getLoggedInUsers
#
# Parameters: none
#
# Returns: @ids - the IDs of the currently logged in users.
#
# Description: This method retrieves the list of currently logged in users 
#              from the database.
#
#==============================================================================
sub getLoggedInUsers
{
    my $self = shift;

    # get the database handle
    my $database = $self->{database};

    # get the logged in users from the database
    my $query = $database->prepare("SELECT * FROM whose_in");
    $query->execute();

    # create an array of logged in user ids to return

    my %ids;

    while ((my @row = $query->fetchrow_array))
    {
        my $id = shift @row;
        my $time = shift @row;

        $ids{$id} = $time;
    }

    return %ids;
}

#==============================================================================
#
# Method name: logout
#
# Parameters: id - the id number of the user being logged out.
#
# Returns: void
#
# Description: This method updates the whose_in table in the database to
#              reflect a user logout.
#
#==============================================================================
sub logout
{
    my $self = shift;
    my $id = shift;

    # get the database handle
    my $database = $self->{database};
    
    # remove the user referenced by ID from the whose_in table
    my $query = $database->prepare("DELETE FROM whose_in WHERE id = ?");
    $query->execute($id);
}

#==============================================================================
#
# Method name: spawn
#
# Parameters: none
#
# Returns: persist - the newly created persist object
#
# Description: This is the constructor for this persist object.
#
#==============================================================================
sub spawn
{
    my $db = &__connectToDB();

    # create new persist object
    my $self = {database => $db};
    bless $self, "Persist";

    return $self;
}

sub test
{
    say "hello.";
}
1;
