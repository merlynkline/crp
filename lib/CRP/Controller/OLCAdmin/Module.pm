package CRP::Controller::OLCAdmin::Module;

use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

use CRP::Model::OLC::Module;
use CRP::Model::OLC::ModuleSet;
use CRP::Model::OLC::CourseSet::WithModule;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub edit {
    my $c = shift;

    $c->_display_module_editor;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
sub save {
    my $c = shift;

    my $module = CRP::Model::OLC::Module->new(id => $c->param('id'), dbh => $c->crp->model);

    my $module_input = {};
    foreach my $field (qw(name notes description title)) {
        $module_input->{$field} = $c->crp->trimmed_param($field);
    }

    foreach my $field (keys %$module_input) {
        try {
            $module->$field($module_input->{$field});
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

    if($c->validation->has_error) {
        $c->stash(msg => 'fix_errors');
        $c->_display_module_editor($module);
    }
    else {
        my $url;
        if($module->id) {
            $c->flash(msg => 'olc_module_update');
            $url = $c->url_for('crp.olcadmin.course.edit')->query(id => $c->param('course_id'));
        }
        else {
            $c->flash(msg => 'olc_module_create');
            $url = $c->url_for('crp.olcadmin.course.pickmodules')->query(course_id => $c->param('course_id'));
        }
        $module->create_or_update;
        return $c->redirect_to($url);
    }
}


sub _display_module_editor {
    my $c = shift;
    my($module) = @_;

    $module = CRP::Model::OLC::Module->new(id => $c->param('id'), dbh => $c->crp->model) unless $module;
    my $module_courses = CRP::Model::OLC::CourseSet::WithModule->new(module_id => $module->id, dbh => $c->crp->model);
    $c->stash(
        module         => $module->view_data,
        course_id      => $c->param('course_id'),
        module_courses => $module_courses->view_data,
    );
    $c->render(template => 'o_l_c_admin/module/editor');
}

1;

