# Don't run if it's not an interactive shell
case "$-" in
 *i*) ;; # interactive shell
 *) return;;
esac

. ~/.bashrc.public
