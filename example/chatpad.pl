use strict;
use warnings;

use AnyEvent::WWW::ChatPad;

my $chat = AnyEvent::WWW::ChatPad->new;
$chat->reg_cb(
    on_error => sub { die @_ },

    on_chat_waiting => sub {
        print "* チャット相手を探してるのでしばらく待ってね！\n";
    },

    on_chat_start => sub {
        print "* チャット相手が見つかったのでチャットを始めるよー！\n";

        my $w; $w = AnyEvent->io (
            fh   => \*STDIN,
            poll => "r",
            cb   => sub {
                my $msg = <STDIN>;
                $chat->send_message($msg) if $msg;

                $w; # guard
            }
        );
    },

    on_chat_end => sub {
        print "* チャット相手がチャットを終了したよ！\n";
    },

    on_chat_mute => sub {
        print "* 相手とChatPadシステムとの通信が途絶えています。しばらく待ったら回復するかも。\n";
    },

    on_system_message => sub {
        print "* $_[1]\n";
    },

    on_message => sub {
        print "> $_[1]\n";
    },

    on_picture => sub {
        print "* チャット相手が画像を更新しました: $_[1]\n";
    },
);

$chat->chat_start;

AnyEvent->condvar->recv;
