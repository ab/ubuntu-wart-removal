#!/bin/sh
set -eux

disable_old() {
    if grep allow-guest /etc/lightdm/lightdm.conf; then
        echo "allow-guest line already present"
        exit 1
    else
        echo 'allow-guest=false' | sudo tee -a /etc/lightdm/lightdm.conf
    fi
}

disable_trusty() {
    conf_file=/etc/lightdm/lightdm.conf.d/50-guest.conf
    sudo mkdir -vp "$(dirname "$conf_file")"

    if [ -e "$conf_file" ]; then
        echo "$conf_file already exists"
        exit 2
    fi

    sudo tee "$conf_file" <<EOM
[SeatDefaults]
allow-guest=false
EOM
}

case "$(lsb_release -cs)" in
    precise)
        disable_old
        ;;

    trusty|utopic)
        disable_trusty
        ;;

    *)
        echo >&2 "Unknown release: $(lsb_release -cs)"
        exit 2
        ;;
esac

