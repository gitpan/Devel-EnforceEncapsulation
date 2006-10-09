use warnings;
use strict;
use Test::More tests => 47;

BEGIN
{
   use_ok 'Devel::EnforceEncapsulation';
}

# Sanity checks: invalid package names
eval { Devel::EnforceEncapsulation->apply_to('000'); };
ok $@, 'Try to apply_to invalid package';
eval { Devel::EnforceEncapsulation->remove_from('000'); };
ok $@, 'Try to remove_from invalid package';

# Test hashes
my $o = Hash_class->new;
$o->foo(1);
is $o->{secret}, 1, 'Unencapsulated classes are not affected';

Devel::EnforceEncapsulation->apply_to('Hash_class');
is $o->{secret}, 1, 'Unencapsulated instances are still not affected';

$o = Hash_class->new;
$o->foo(2);
is $o->foo(), 2, 'hash accessor';
eval { my $val = $o->{secret}; };
ok $@, 'Cannot reach into objects';
eval { my @keys = keys %$o; };
ok $@, 'Cannot reach into objects';
eval { my @vals = values %$o; };
ok $@, 'Cannot reach into objects';
eval { my @vals = each %$o; };
ok $@, 'Cannot reach into objects';
eval { my @vals = @{$o}{qw(secret)}; };
ok $@, 'Cannot reach into objects';
eval { my $str = "$o->{secret}"; };
ok $@, 'Cannot reach into objects';

my $s = Hash_subclass->new;
$s->foo('s');
is $s->foo(), 's', 'subclass accessor';
eval { my $val = $s->{secret}; };
ok $@, 'Cannot reach into objects';

Devel::EnforceEncapsulation->remove_from('Hash_class');
eval { my $val = $o->{secret}; };
ok $@, 'Still cannot reach into runtime injected objects';

$o = Hash_class->new;
$o->foo(3);
is $o->{secret}, 3, 'Unencapsulated classes are once again not affected';

# Test super classes
Devel::EnforceEncapsulation->apply_to('A_class');
my $a = A_superclass->new;
my $b = A_class->new;
my $c = A_subclass->new;

$a->a(1);
$b->a(2);
$c->a(3);
is $a->a(), 1, 'superclass';
is $b->a(), 2, 'class';
is $b->b(), 2, 'class';
is $c->a(), 3, 'subclass';
is $c->b(), 3, 'subclass';
is $c->c(), 3, 'subclass';
is $a->{secret}, 1, 'Can reach into superclass objects';
eval { my $val = $b->{secret}; };
ok $@, 'Cannot reach into objects';
eval { my $val = $c->{secret}; };
ok $@, 'Cannot reach into objects';

$b->b(4);
$c->b(5);
is $a->a(), 1, 'superclass';
is $b->a(), 4, 'class';
is $b->b(), 4, 'class';
is $c->a(), 5, 'subclass';
is $c->b(), 5, 'subclass';
is $c->c(), 5, 'subclass';
is $a->{secret}, 1, 'Can reach into superclass objects';
eval { my $val = $b->{secret}; };
ok $@, 'Cannot reach into objects';
eval { my $val = $c->{secret}; };
ok $@, 'Cannot reach into objects';

$c->c(6);
is $a->a(), 1, 'superclass';
is $b->a(), 4, 'class';
is $b->b(), 4, 'class';
is $c->a(), 6, 'subclass';
is $c->b(), 6, 'subclass';
is $c->c(), 6, 'subclass';
is $a->{secret}, 1, 'Can reach into superclass objects';
eval { my $val = $b->{secret}; };
ok $@, 'Cannot reach into objects';
eval { my $val = $c->{secret}; };
ok $@, 'Cannot reach into objects';


# Test other types

Devel::EnforceEncapsulation->apply_to('Array_class');
Devel::EnforceEncapsulation->apply_to('Scalar_class');

$o = Array_class->new();
$o->foo(4);
is $o->foo(), 4, 'array accessor';
eval { my $val = $o->[ 0 ]; };
ok $@, 'Array direct access';

$o = Scalar_class->new();
$o->foo(5);
is $o->foo(), 5, 'scalar accessor';
eval { my $val = $$o; };
ok $@, 'Scalar direct access';

exit;

{   package Hash_class;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }

    sub foo {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}
{   package Hash_subclass;
    use base 'Hash_class';
}


{   package A_superclass;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }
    sub a {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}
{   package A_class;
    use base 'A_superclass';
    sub b {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}
{   package A_subclass;
    use base 'A_class';

    sub c {
        my $self = shift;
        $self->{ secret } = shift if @_;
        return $self->{ secret };
    }
}

{   package Array_class;

    sub new {
        my $class = shift;
        return bless [], $class;
    }

    sub foo {
        my $self = shift;
        $self->[ 0 ] = shift if @_;
        return $self->[ 0 ];
    }
}

{   package Scalar_class;

    sub new {
        my $class = shift;
        return bless \( my $obj ), $class;
    }

    sub foo {
        my $self = shift;
        ${$self} = shift if @_;
        return ${$self};
    }
}

