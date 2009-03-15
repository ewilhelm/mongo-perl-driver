use strict;
use warnings;
use Test::More tests => 22;
use Test::Exception;

use MongoDB;

my $conn = MongoDB::Connection->new;
my $db   = $conn->get_database('test_database');
my $coll = $db->get_collection('test_collection');
isa_ok($coll, 'MongoDB::Collection');

is($coll->name, 'test_collection', 'get name');

$db->drop;

my $id = $coll->insert({ just => 'another', perl => 'hacker' });
is($coll->count, 1);

$coll->update({ _id => $id }, {
    just => 'another',
    mongo => 'hacker',
    with => { a => 'reference' },
    and => [qw/an array reference/],
});
is($coll->count, 1);

is($coll->count({ mongo => 'programmer' }), 0);
is($coll->count({ mongo => 'hacker'     }), 1);
is($coll->count({ 'with.a' => 'reference' }), 1);

my $obj = $coll->find_one;
is($obj->{mongo} => 'hacker');
is(ref $obj->{with}, 'HASH');
is($obj->{with}->{a}, 'reference');
is(ref $obj->{and}, 'ARRAY');
is_deeply($obj->{and}, [qw/an array reference/]);
ok(!exists $obj->{perl});

lives_ok {
    $coll->validate;
} 'validate';

$coll->remove($obj);
is($coll->count, 0);

$coll->drop;
ok(!$coll->get_indexes, 'no indexes yet');

$coll->ensure_index([qw/foo bar baz/]);
$coll->ensure_index([qw/foo bar/]);

my @indexes = $coll->get_indexes;
is(scalar @indexes, 2, 'two indexes');
is_deeply(
    [sort keys %{ $indexes[0]->{key} }],
    [sort qw/foo bar baz/],
);
is_deeply(
    [sort keys %{ $indexes[1]->{key} }],
    [sort qw/foo bar/],
);

$coll->drop_index($indexes[0]->{name});
@indexes = $coll->get_indexes;
is(scalar @indexes, 1);
is_deeply(
    [sort keys %{ $indexes[0]->{key} }],
    [sort qw/foo bar/],
);

$coll->drop;
ok(!$coll->get_indexes, 'no indexes after dropping');

END {
    $db->drop;
}
