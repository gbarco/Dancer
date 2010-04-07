package Dancer;

use strict;
use warnings;
use Carp 'confess';
use vars qw($VERSION $AUTHORITY @EXPORT);

use Dancer::Config 'setting';
use Dancer::FileUtils;
use Dancer::GetOpt;
use Dancer::Error;
use Dancer::Helpers;
use Dancer::Logger;
use Dancer::Renderer;
use Dancer::Response;
use Dancer::Route;
use Dancer::Session;
use Dancer::SharedData;
use Dancer::Handler;
use Dancer::ModuleLoader;

use base 'Exporter';

$AUTHORITY = 'SUKRIA';
$VERSION   = '1.173_01';
@EXPORT    = qw(
  any
  before
  cookies
  config
  content_type
  dance
  debug
  del
  dirname
  error
  false
  from_json
  from_yaml
  from_xml
  get
  header
  headers
  layout
  load
  logger
  mime_type
  options
  params
  pass
  path
  post
  prefix
  put
  r
  redirect
  request
  send_file
  send_error
  set
  set_cookie
  session
  splat
  status
  template
  to_json
  to_yaml
  to_xml
  true
  upload
  uri_for
  var
  vars
  warning
);

# Dancer's syntax
my $_serializers;

sub any          { Dancer::Route->add_any(@_) }
sub before       { Dancer::Route->before_filter(@_) }
sub cookies      { Dancer::Cookies->cookies }
sub config       { Dancer::Config::settings() }
sub content_type { Dancer::Response::content_type(@_) }
sub debug        { Dancer::Logger->debug(@_) }
sub dirname      { Dancer::FileUtils::dirname(@_) }
sub error        { Dancer::Logger->error(@_) }
sub send_error   { Dancer::Helpers->error(@_) }
sub false        {0}
sub from_json {
    if ($_serializers->{JSON}) {
        Dancer::Serializer::JSON->deserialize(@_);
    }
    else {
        # should we die ?
    }
}
sub from_yaml {
    if ($_serializers->{YAML}) {
        Dancer::Serializer::YAML->deserialize(@_);
    }
    else {
        # should we die ?
    }
}
sub from_xml {
    if ($_serializers->{XML}) {
        Dancer::Serializer::XML->deserialize(@_);
    }
    else {
        # should we die ?
    }
}
sub get {
    Dancer::Route->add('head', @_);
    Dancer::Route->add('get',  @_);
}
sub headers    { Dancer::Response::headers(@_); }
sub header     { goto &headers; }                      # goto ftw!
sub layout     { set(layout => shift) }
sub logger     { set(logger => @_) }
sub load       { require $_ for @_ }
sub mime_type  { Dancer::Config::mime_types(@_) }
sub params     { Dancer::SharedData->request->params(@_) }
sub pass       { Dancer::Response->pass }
sub path       { Dancer::FileUtils::path(@_) }
sub post       { Dancer::Route->add('post', @_) }
sub prefix     { Dancer::Route->prefix(@_) }
sub del        { Dancer::Route->add('delete', @_) }
sub options    { Dancer::Route->add('options', @_) }
sub put        { Dancer::Route->add('put', @_) }
sub r          { {regexp => $_[0]} }
sub redirect   { Dancer::Helpers::redirect(@_) }
sub request    { Dancer::SharedData->request }
sub send_file  { Dancer::Helpers::send_file(@_) }
sub set        { setting(@_) }
sub set_cookie { Dancer::Helpers::set_cookie(@_) }

sub session {
    if (@_ == 0) {
        return Dancer::Session->get;
    }
    else {
        return (@_ == 1)
          ? Dancer::Session->read(@_)
          : Dancer::Session->write(@_);
    }
}
sub splat    { @{Dancer::SharedData->request->params->{splat}} }
sub status   { Dancer::Response::status(@_) }
sub template { Dancer::Helpers::template(@_) }
sub true     {1}
sub to_json {
    if ($_serializers->{JSON}) {
        Dancer::Serializer::JSON->serialize(@_);
    }
    else {
        # should we die ?
    }
}
sub to_yaml {
    if ($_serializers->{YAML}) {
        Dancer::Serializer::YAML->serialize(@_);
    }
    else {
        # should we die ?
    }
}
sub to_xml {
    if ($_serializers->{XML}) {
        Dancer::Serializer::XML->serialize(@_);
    }
    else {
        # should we die ?
    }
}
sub upload   { Dancer::SharedData->request->upload(@_) }
sub uri_for  { Dancer::SharedData->request->uri_for(@_) }
sub var      { Dancer::SharedData->var(@_) }
sub vars     { Dancer::SharedData->vars }
sub warning  { Dancer::Logger->warning(@_) }

# When importing the package, strict and warnings pragma are loaded,
# and the appdir detection is performed.
sub import {
    my ($class,   $symbol) = @_;
    my ($package, $script) = caller;

    for my $name (qw/JSON YAML XML/) {
        my $module = "Dancer::Serializer::$name";
        if (Dancer::ModuleLoader->load($module)) {
            $module->init;
            $_serializers->{$name} = 1;
        }
    }
    strict->import;
    warnings->import;

    $class->export_to_level(1, $class, @EXPORT);

    # if :syntax option exists, don't change settings
    if ($symbol && $symbol eq ':syntax') {
        return;
    }

    Dancer::GetOpt->process_args();
    setting appdir => dirname(File::Spec->rel2abs($script));
    setting public => path(setting('appdir'), 'public');
    setting views  => path(setting('appdir'), 'views');
    setting logger => 'file';
    setting confdir => $ENV{DANCER_CONFDIR} || setting('appdir');
    Dancer::Config->load;
}

# Start/Run the application with the chosen apphandler
sub dance {
    my ($class, $request) = @_;
    Dancer::Config->load;
    Dancer::Handler->get_handler()->dance($request);
}

1;
__END__

=pod

=head1 NAME

Dancer - Lightweight yet powerful web application framework


=head1 SYNOPSIS

    #!/usr/bin/perl
    use Dancer;

    get '/hello/:name' => sub {
        return "Why, hello there " . params->{name};
    };

    dance;

The above is a basic but functional web app created with Dancer.  If you want to
see more examples and get up and running quickly, check out the
L<Dancer::Cookbook>.  For examples on deploying your Dancer applications, see
L<Dancer::Deployment>.


=head1 DESCRIPTION

Dancer is a web application framework designed to be as effortless as possible
for the developer, taking care of the boring bits as easily as possible, yet
staying out of your way and letting you get on with writing your code.

Dancer aims to provide the simplest way for writing web applications, and
offers the flexibility to scale between a very simple lightweight web service
consisting of a few lines of code in a single file, all the way up to a more
complex fully-fledged web application with session support, templates for views
and layouts, etc.

If you don't want to write CGI scripts by hand, and find Catalyst too big or
cumbersome for your project, Dancer is what you need.

Dancer has few pre-requisites, so your Dancer webapps will be easy to deploy.

Dancer apps can be used with a an embedded web server (great for easy testing),
and can run under PSGI/Plack for easy deployment in a variety of webserver
environments.

=head1 METHODS

=head2 any

Define a route for multiple methods at one.

    any ['get', 'post'] => '/myaction' => sub {
        # code
    };

Or even, a route handler that would match any HTTP methods:

    any '/myaction' => sub {
        # code
    };

=head2 before

=head2 cookies

=head2 config

=head2 content_type

=head2 debug

=head2 dirname

=head2 error

=head2 send_error

=head2 fale

=head2 get

Define a route for B<GET> method.

    get '/' => sub {
        return "Hello world";
    }

=head2 headers

=head2 header

=head2 layout

=head2 logger

=head2 load

=head2 mime_type

=head2 params

=head2 pass

=head2 path

=head2 post

=head2 prefix

A prefix can be defined for each route handler, like this:

    prefix '/home';

From here, any route handler is defined to /home/*

    get '/page1' => sub {}; # will match '/home/page1'

You can unset the prefix value

    prefix undef;
    get '/page1' => sub {}; will match /page1

=head2 del

=head2 options

=head2 put

=head2 r

=head2 redirect

=head2 request

=head2 send_file

=head2 set

=head2 set_cookie

=head2 session

=head2 splat

=head2 status

=head2 template

=head2 upload

=head2 uri_for

=head2 var

=head2 vars

=head2 warning

=head1 AUTHOR

This module has been written by Alexis Sukrieh <sukria@cpan.org> and others,
see the AUTHORS file that comes with this distribution for details.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<http://github.com/sukria/Dancer>


=head1 GETTING HELP / CONTRIBUTING

The Dancer development team can be found on #dancer on irc.perl.org:
L<irc://irc.perl.org/dancer>

There is also a Dancer users mailing list available - subscribe at:

L<http://lists.perldancer.org/cgi-bin/listinfo/dancer-users>


=head1 DEPENDENCIES

Dancer depends on the following modules:

The following modules are mandatory (Dancer cannot run without them)

=over 8

=item L<HTTP::Server::Simple::PSGI>

=item L<HTTP::Body>

=item L<MIME::Types>

=item L<URI>

=back

The following modules are optional

=over 8

=item L<Template> : In order to use TT for rendering views

=item L<YAML> : needed for configuration file support

=item L<File::MimeInfo::Simple>

=back

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 SEE ALSO

Main Dancer web site: L<http://perldancer.org/>.

The concept behind this module comes from the Sinatra ruby project,
see L<http://www.sinatrarb.com/> for details.

=cut
