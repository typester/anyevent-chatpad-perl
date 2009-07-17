use inc::Module::Install;
name 'WebService-ChatPad';
all_from 'lib/WebService/ChatPad.pm';

requires 'AnyEvent';
requires 'HTTP::Request::Common';

test_requires 'Test::More';
use_test_base;

author_tests('xt');

auto_include;
WriteAll;
