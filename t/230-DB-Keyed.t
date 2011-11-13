use Test::More tests => 5;

use lib 't';

my $module;
BEGIN { $module = 'User::Config::DB::Keyed'};
BEGIN { use_ok($module) };

use User::Config;
use User::Config::Test;
use DBI;

my $dbfile = "keyed.db";
my $table = "test";
unlink $dbfile if -f $dbfile;
my $dbcon = "dbi:SQLite:$dbfile";
my $dbh = DBI->connect($dbcon, undef, undef, { AutoCommit => 1 });
$dbh->do("CREATE TABLE $table ( uid text, item text, value text )");

my $uc = User::Config::instance();
ok($uc->db("Keyed", { db => $dbcon, table => $table }), "Keyed DB-client connected");
my $mod = User::Config::Test->new;
$mod->context({user => "foo"});
is($mod->setting, "defstr", "Default value (single bind)");
$mod->setting("bla");
is($mod->setting, "bla", "saved Keyed setting");
$mod->setting("blablupp");
is($mod->setting, "blablupp", "modified Keyed setting");
