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

    my @ids;

    while ((my @row = $query->fetchrow_array))
    {
        push @ids, shift @row;
    }

    return @ids;
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
    $query->execute("$id");
}

#==============================================================================
#
# Method name: login
#
# Parameters: id - the id number of the user being logged out.
#
# Returns: void
#
# Description: This method updates the whose_in table in the database to
#              reflect a user login.
#
#==============================================================================
sub login
{
    my $self = shift;
    my $id = shift;

    # get the database handle
    my $database = $self->{database};
    
    # remove the user referenced by ID from the whose_in table
    my $query = $database->prepare("INSERT INTO whose_in (id) VALUES(?)");
    $query->execute($id);
}


#==============================================================================
#
# Method name: logAccess
#
# Parameters: id                - the id number of the user being logged in/out
#             login/logout      - [1 -> login, 0 -> logout]
#             purpose           - why the user is in
#
# Returns: void
#
# Description: This method is used to record login/logout events in the 
#              access_log table in the database.
#
#==============================================================================
sub logAccess
{
    my $self = shift;
    my $id = shift;
    my $in_out = shift;
    my $purpose = shift;

    # get the database handle
    my $database = $self->{database};

    # set the parameter for indicating a login or logout
    my $login_flag;
    if ($in_out == 1) 
    {
        $login_flag = "true";
    }
    else 
    {
        $login_flag = "false";
    }

    # add the login/logout event to the database.
    my $query = $database->prepare("INSERT INTO ".
                                   "access_log(time,id,login_logout,purpose) ".
                                 " VALUES(current_timestamp,?,$login_flag,?)");
    $query->execute($id,$purpose);
}


#==============================================================================
#
# Method Name: logError
#
# Parameters: id    - The RFID in process when the error occurred.
#             error - The error message.
#
# Returns: void
#
# Description: This method logs an error to the error_log table of the databse.
#
#==============================================================================
sub logError
{
    my $self = shift;
    my $id = shift;
    my $error = shift;

    # get the database handle
    my $database = $self->{database};

    my $query = $database->prepare("INSERT INTO error_log(time,id,error) ".
                                   "VALUES(current_timestamp,?,?)");
    $query->execute("$id",$error);
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