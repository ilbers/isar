# Copy optional lighttpd modules and assets from the target sysroot.
for source in "${dracutsysrootdir}"/usr/lib/*/lighttpd/*.so \
			  "${dracutsysrootdir}"/usr/share/lighttpd/*; do
	[[ -e "$source" ]] || continue
	inst_simple "$source" "${source#"$dracutsysrootdir"}"
done

inst_simple "${moddir}/lighttpd.service" "$systemdsystemunitdir/lighttpd.service"
inst_simple "${moddir}/lighttpd.conf" /etc/lighttpd/lighttpd.conf

# use the sysuser lighttpd config to create the necessary user
inst_sysusers lighttpd.conf

mkdir -p -m 0700 "$initdir/etc/lighttpd/"
mkdir -p -m 0700 "$initdir/var/cache/lighttpd/compress"
mkdir -p -m 0700 "$initdir/var/cache/lighttpd/uploads"
mkdir -p -m 0700 "$initdir/var/log/lighttpd/"
mkdir -p -m 0755 "$initdir/var/www/html"

inst_simple "${dracutsysrootdir}"/usr/share/lighttpd/index.html /var/www/html/index.html
touch "$moddir"/error.log
inst_simple "$moddir"/error.log /var/log/lighttpd/error.log
chown -R www-data:www-data "$initdir/var/log/lighttpd/"
systemctl -q --root "$initdir" enable lighttpd
