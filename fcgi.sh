!/usr/bin/perl
use FCGI;
use Socket;
use POSIX qw(setsid);
require 'syscall.ph';
&daemonize;
END() { } BEGIN() { }
*CORE::GLOBAL::exit = sub { die "fakeexit\nrc=".shift()."\n"; };
eval q{exit};
if ($@) {
        exit unless $@ =~ /^fakeexit/;
};
&main;
sub daemonize() {
    chdir '/'                 or die "Can't chdir to /: $!";
    defined(my $pid = fork)   or die "Can't fork: $!";
    exit if $pid;
    setsid                    or die "Can't start a new session: $!";
    umask 0;
}
sub main {
        $socket = FCGI::OpenSocket( "/usr/local/nginx/fastcgi_temp/perl_cgi-dispatch.sock", 10 );
        $request = FCGI::Request( \*STDIN, \*STDOUT, \*STDERR, \%req_params, $socket );
        if ($request) { request_loop()};
            FCGI::CloseSocket( $socket );
}
sub request_loop {
    while( $request->Accept() >= 0 ) {
        $stdin_passthrough ='';
        $req_len = 0 + $req_params{'CONTENT_LENGTH'};
        if (($req_params{'REQUEST_METHOD'} eq 'POST') && ($req_len != 0) ) {
            my $bytes_read = 0;
            while ($bytes_read < $req_len) {
                    my $data = '';
                    my $bytes = read(STDIN, $data, ($req_len - $bytes_read));
                    last if ($bytes == 0 || !defined($bytes));
                    $stdin_passthrough .= $data;
                    $bytes_read += $bytes;
            }
        }
        if ( (-x $req_params{SCRIPT_FILENAME}) && (-s $req_params{SCRIPT_FILENAME}) && (-r $req_params{SCRIPT_FILENAME}) ) {
            pipe(CHILD_RD, PARENT_WR);
            my $pid = open(KID_TO_READ, "-|");
            unless(defined($pid)) {
                    print("Content-type: text/plain\r\n\r\n");
                    print "Error: CGI app returned no output - Executing $req_params {SCRIPT_FILENAME} failed !\n";
                    next;
            }
            if ($pid > 0) {
                    close(CHILD_RD);
                    print PARENT_WR $stdin_passthrough;
                    close(PARENT_WR);
                    while(my $s = <KID_TO_READ>) { print $s; }
                    close KID_TO_READ;
                    waitpid($pid, 0);
            }
            else {
                    foreach $key ( keys %req_params) {
                    $ENV{$key} = $req_params{$key};
                    }
                    if ($req_params{SCRIPT_FILENAME} =~ /^(.*)\/[^\/]+$/) {
                                chdir $1;
                        }
                    close(PARENT_WR);
                    close(STDIN);
                    syscall(&SYS_dup2, fileno(CHILD_RD), 0);
                    exec($req_params{SCRIPT_FILENAME});
                    die("exec failed");
                }
        }
        else {
            print("Content-type: text/plain\r\n\r\n");
            print "Error: No such CGI app - $req_params{SCRIPT_FILENAME} may not exist or is not executable by this process.\n";
            }
    }
}




/usr/local/nginx/conf/fastcgi_params1    
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_param QUERY_STRING     $query_string;
    fastcgi_param REQUEST_METHOD   $request_method;
    fastcgi_param CONTENT_TYPE     $content_type;
    fastcgi_param CONTENT_LENGTH   $content_length;
    fastcgi_param GATEWAY_INTERFACE CGI/1.1;
    fastcgi_param SERVER_SOFTWARE    nginx;
    fastcgi_param SCRIPT_NAME        $fastcgi_script_name;
    fastcgi_param REQUEST_URI        $request_uri;
    fastcgi_param DOCUMENT_URI       $document_uri;
    fastcgi_param DOCUMENT_ROOT      $document_root;
    fastcgi_param SERVER_PROTOCOL    $server_protocol;
    fastcgi_param REMOTE_ADDR        $remote_addr;
    fastcgi_param REMOTE_PORT        $remote_port;
    fastcgi_param SERVER_ADDR        $server_addr;
    fastcgi_param SERVER_PORT        $server_port;
    fastcgi_param SERVER_NAME        $server_name;
    fastcgi_read_timeout 60;




server {
            listen      59521;
            server_name  www.test.cn;
            location / {
                root   /data/awstats;
                index  index.html index.htm;
            }
            location ~* ^/cgi-bin/.*\.pl$ {
                root /usr/local/awstats/wwwroot;
                fastcgi_pass unix:/usr/local/nginx/fastcgi_temp/perl_cgi-dispatch.sock;
                fastcgi_index index.pl;
                include  fastcgi_params1;
                charset gb2312;
            }
            location ~ ^/icon/ {        # 图标目录
                root   /usr/local/awstats/wwwroot;
                index  index.html;
                access_log off;
                error_log off;
            }
    }