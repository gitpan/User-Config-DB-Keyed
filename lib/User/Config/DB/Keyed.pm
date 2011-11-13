package User::Config::DB::Keyed;

use strict;
use warnings;

use Moose;
with 'User::Config::DB';
use DBI;

our $VERSION = '0.01_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

=pod

=head1 NAME

User::Config::DB::Keyed - Store User-Configuration in a large Key-Value-Table.

=head1 SYNOPSIS

  use User::Config;

  my $uc = User::Config->instance;
  $uc->db("Keyed",  { table => "user", db => "dbi:SQLite:user.sqlite" });

=head1 DESCRIPTION

This is a database-backend for L<User::Config>. The options will be stored
within a table consisting of - at least - three columns:

=over 4

=item user - will save the current users name (default: "uid")

=item item - will save the namespace and the name of the option
(default: "item")

=item value - will store the value (default: "value")

=back

The names of these columns as well of the tables are configurable. Further columns
wont be touched.

=head2 ATTRIBUTES

All attributes are read-only and should be given at the time of initialization.

=head3 table

This attribute must be given and contain the name of the table within the
database to use.

=cut

has table => ( 
	is => "ro",
       	required => 1,
       	isa => "Str",
);

=head3 db

This attribute must be given, too. It consits of a L<DBI>-string to connect to the
database.

=cut

has db => (
	is => "ro",
       	required => 1,
       	isa => "Str",
);

=head3 db_user and db_pwd

These attributes contain optional username and password for the database-connection

=cut

has [ qw/db_user db_pwd/ ] => (
	is => "ro",
	isa => "Str",
);

=head3 user_column, item_column and value_column

this will contain the names of the columns used to store the user, item
and value. The default values are shown above.

=cut

has value_column => (
	is => "ro",
	default => "value",
	isa => "Str",
);
has user_column => (
	is => "ro",
	default => "uid",
	isa => "Str",
);
has item_column => (
	is => "ro",
	default => "item",
	isa => "Str",
);

=head2 METHODS

=for comment
C<BUILD> will prepare the statemennts used too communicate with the database

=cut

sub BUILD {
	my ($self) = @_;

	my $valcol = $self->value_column;
	my $usercol = $self->user_column;
	my $itemcol = $self->item_column;
	my $table = $self->table;
	my $gstmt = "SELECT $valcol FROM $table ".
		"WHERE $usercol = ? AND $itemcol = ?";
	my $pstmt = "SELECT COUNT(*) FROM $table ".
		"WHERE $usercol = ? AND $itemcol = ?";
	my $istmt = "INSERT INTO $table ( $valcol, $usercol, $itemcol ) ".
		"VALUES ( ?, ?, ? )";
	my $ustmt = "UPDATE $table SET $valcol = ? ".
		"WHERE $usercol = ? AND $itemcol = ?";

	my $dbh = DBI->connect( $self->db, $self->db_user, $self->db_pwd,
	       	{AutoCommit => 1} );
	croak $dbh->errstr if $dbh->err;
	$self->{get} = $dbh->prepare($gstmt),
	$self->{insert} = $dbh->prepare($istmt),
	$self->{update} = $dbh->prepare($ustmt),
	$self->{isset} = $dbh->prepare($pstmt),
}

=head3 C<<$db->set($package, $user, $option_name, $context, $value)>>

assigns the value for the given user to the option within a package.
See L<User::Config::DB>

=cut

sub set {
	my ($self, $namespace, $user, $name, $ctx, $value) = @_;
	my $item = $namespace."::".$name;
	my $stmt = $self->isset($namespace, $user, $name, $ctx)
			? $self->{update}
			: $self->{insert};
	return $stmt->execute($value, $user, $item);
}

=head3 C<<$db->isset($package, $user, $option_name, $context)>>

Checks wether the option was set.
See L<User::Config::DB>

=cut

sub isset {
	my ($self, $namespace, $user, $name, $ctx) = @_;
	$self->{isset}->execute($user, $namespace."::".$name);
	return ${$self->{isset}->fetchrow_arrayref()}[0];
}

=head3 C<<$db->get($package, $user, $option_name, $context)>>

retrieves the currently set value.
See L<User::Config::DB>

=cut

sub get {
	my ($self, $namespace, $user, $name) = @_;
	$self->{get}->execute($user, $namespace."::".$name);
	return ${$self->{get}->fetchrow_arrayref()}[0];
}

=head1 SEE ALSO

L<User::Config>
L<User::Config::DB>
L<DBI>

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
1;

