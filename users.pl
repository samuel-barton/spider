use v5.22;
use Persist;

say "Add a user to the database.";
print "ID: ";
my $id = <stdin>;
print "name: ";
my $name = <stdin>;
print "password: ";
my $password = <stdin>;
print "photo path: ";
my $photo_path = <stdin>;

# trim newlines from all input parameters
chomp($id);
chomp($name);
chomp($password);
chomp($photo_path);

my $database = Persist->spawn();
$database->addUser($id,$name,$password,$photo_path);
say "User added to database.";
