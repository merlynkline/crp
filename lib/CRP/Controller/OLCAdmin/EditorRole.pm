package CRP::Controller::OLCAdmin::EditorRole;

use Mojo::Role;

use Try::Tiny;

sub _collect_input {
    my $c = shift;
    my($store, $fields) = @_;

    my $input = {};
    foreach my $field (@$fields) {
        $input->{$field} = $c->crp->trimmed_param($field);
    }

    foreach my $field (keys %$input) {
        try {
            $store->$field($input->{$field});
        }
        catch {
            my $error = $_;
            if($error =~ m{^CRP::Util::Types::(.+?) }) {
                $c->validation->error($field => ["invalid_column_$1"]);
            }
            else {
                die "$field: $error";
            }
        }
    }
}

sub _page_id {
    my $c = shift;

    my $page_id = $c->param('page_id');
    return $page_id;
}

sub _module_id {
    my $c = shift;

    my $module_id = $c->param('module_id');
    return $module_id;
}

sub _course_id {
    my $c = shift;

    my $course_id = $c->param('course_id');
    return $course_id;
}

1;

