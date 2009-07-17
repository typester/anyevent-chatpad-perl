use inc::Module::Install;
name 'AnyEvent-WWW-ChatPad';
all_from 'lib/AnyEvent/WWW/ChatPad.pm';

requires 'Any::Moose';
requires 'AnyEvent';
requires 'Object::Event';
requires 'HTTP::Request::Common';

test_requires 'Test::More';
use_test_base;

author_tests('xt');

auto_include;
WriteAll;
