package CRP::Model::OLC::ModuleSet;
use Moose;
use namespace::autoclean;

use constant _MEMBER_CLASS => 'CRP::Model::OLC::Module';

with 'CRP::Model::DBICIDObjectSet';

sub _where_clause {
    return {};
}

__PACKAGE__->meta->make_immutable;

1;

