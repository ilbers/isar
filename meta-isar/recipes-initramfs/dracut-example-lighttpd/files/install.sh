inst_multiple -o /usr/lib/lighttpd/*.so
inst_multiple -o /usr/share/lighttpd/*

inst_simple "${moddir}/lighttpd.service" "$systemdsystemunitdir/lighttpd.service"
inst_simple "${moddir}/lighttpd.conf" /etc/lighttpd/lighttpd.conf

# use the sysuser lighttpd config to create the necessary user
inst_sysusers lighttpd.conf

mkdir -p -m 0700 "$initdir/etc/lighttpd/"
mkdir -p -m 0700 "$initdir/var/cache/lighttpd/compress"
mkdir -p -m 0700 "$initdir/var/cache/lighttpd/uploads"
mkdir -p -m 0700 "$initdir/var/log/lighttpd/"
mkdir -p -m 0755 "$initdir/var/www/html"

/usr/bin/install -m 0644 /usr/share/lighttpd/index.html "$initdir/var/www/html/index.html"
touch "$moddir"/error.log
/usr/bin/install -m 0644 "$moddir"/error.log "$initdir/var/log/lighttpd/error.log"
chown -R www-data:www-data "$initdir/var/log/lighttpd/"
systemctl -q --root "$initdir" enable lighttpd
