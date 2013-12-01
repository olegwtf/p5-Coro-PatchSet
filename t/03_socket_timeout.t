use strict;
use Test::More;
use Coro::PatchSet::Socket;
use Coro::Socket;

my ($pid, $host, $port) = make_broken_http_server();

my $sock = Coro::Socket->new(PeerHost => $host, PeerPort => $port, Timeout => 5);

isa_ok($sock, 'Coro::Socket');
is(${*$sock}{io_socket_timeout}, 5, 'timeout specified');
$sock->close();

if (ref $pid) {
	$pid->kill(15);
}
else {
	kill 15, $pid;
}

($pid, $host, $port) = make_broken_http_server();

use Coro::LWP;
use LWP;

diag "3 sec for next test";
my $ua = LWP::UserAgent->new(timeout => 3);
my $start = time;
my $resp = $ua->get(sprintf('http://%s:%d', $host, $port));
ok(time-$start<10, 'lwp timed out');

if (ref $pid) {
	$pid->kill(15);
}
else {
	kill 15, $pid;
}

done_testing;

sub make_broken_http_server {
	use IO::Socket;
	
	my $serv = IO::Socket::INET->new(Listen => 1)
		or die $@;
	
	my $serv_code = sub {
		while (my $sock = $serv->accept()) {
			sleep 10;
			$sock->close();
		}
	};
	
	my $child;
	if ($^O eq 'MSWin32') {
		require threads;
		$child = threads->create(sub {
			$SIG{TERM} = sub { threads->exit() };
			$serv_code->();
		});
		$child->detach();
	}
	else {
		defined($child = fork())
			or die $!;
		
		if ($child == 0) {
			$serv_code->();
			exit;
		}
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}
