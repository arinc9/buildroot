#!/bin/sh

# You don't usually need to touch this file at all, the full configuration
# of the bridge can be done in a standard way on /etc/network/interfaces.

# Have a look at /usr/share/doc/bridge-utils/README.Debian if you want
# more info about the way on wich a bridge is set up on Debian.

bridge_parse_ports()
{
  while [ x"${1+set}" = xset ]
  do
    # For compatibility: the `all' option.
    case $1 in
      all)
	shift &&
	set regex eth.\* em.\* en.\* 'p[0-9].*' noregex "$@"
	;;
    esac

    # Primitive state machine...
    case $1-`uname -s` in
      regex-Linux)
	all_interfaces=`sed -n 's%^[\ ]*\([^:]*\):.*$%\1%p' < /proc/net/dev`
	shift
	;;
      regex-*)
	echo -n "$0 needs to be ported for your `uname -s` system.  " >&2
	echo "Trying to continue nevertheless." >&2
	shift
	;;
      noregex-*)
	all_interfaces=
	unset all_interfaces
	shift
	;;
    esac

    case ${all_interfaces+regex}-${1+set} in
      regex-set)
	# The following interface specification are to be parsed as regular
	# expressions against all interfaces the system provides.
	i=`egrep "^$1$" << EOAI
$all_interfaces
EOAI
`
	shift
	;;
      *-set)
	# Literal interfaces.
	i=$1
	shift
	;;
      *)
	# No interface specification is following.
	i=
	;;
    esac

    echo $i
  done
}

create_vlan_port()
{
# port doesn't yet exist
if [ ! -e "/sys/class/net/$port" ]
then
  local dev="${port%.*}"
  # port is a vlan and the device exists?
  if [ "$port" != "$dev" ] && [ -e "/sys/class/net/$dev" ]
  then
    if [ -f /proc/sys/net/ipv6/conf/$dev/disable_ipv6 ]
    then
      echo 1 > /proc/sys/net/ipv6/conf/$dev/disable_ipv6
    fi
    ip link set "$dev" up
    ip link add link "$dev" name "$port" type vlan id "${port#*.}"
  fi
fi
}

destroy_vlan_port()
{
# port exists
if [ -e "/sys/class/net/$port" ]
then
  local dev="${port%.*}"
  # port is a vlan
  if [ "$port" != "$dev" ]
  then
    ip link delete "$port"
  fi
fi
}

case "$IF_BRIDGE_PORTS" in
    "")
	exit 0
	;;
    none)
	INTERFACES=""
	;;
    *)
	INTERFACES="$IF_BRIDGE_PORTS"
	;;
esac

# Overload bridge_hw, now it can be a device as well as an address
# The device can exist or not, then it is emptied
if [ "$IF_BRIDGE_HW" ] && ! echo "$IF_BRIDGE_HW"|grep -q "..:..:..:..:..:.."; then
  IF_BRIDGE_HW="$(ip link show dev "$IF_BRIDGE_HW" 2>/dev/null|sed -n "s|.*link/ether \([^ ]*\) brd.*|\1|p")"
fi
# Previous work (create the interface)
if [ "$MODE" = "start" ] && [ ! -d /sys/class/net/$IFACE ]; then
  ip link add dev $IFACE type bridge || exit 1
  if [ "$IF_BRIDGE_HW" ]; then
    sleep 1
    ip link set dev $IFACE address $IF_BRIDGE_HW
  fi
# Wait for the ports to become available
  if [ "$IF_BRIDGE_WAITPORT" ]
  then
    set x $IF_BRIDGE_WAITPORT &&
    shift &&
    WAIT="$1" &&
    shift &&
    WAITPORT="$@" &&
    if [ -z "$WAITPORT" ];then WAITPORT="$IF_BRIDGE_PORTS";fi &&
    STARTTIME=$(date +%s) &&
    NOTFOUND="true" &&
    /bin/echo -e "\nWaiting for a max of $WAIT seconds for $WAITPORT to become available." &&
    while [ "$(($(date +%s)-$STARTTIME))" -le "$WAIT" ] && [ -n "$NOTFOUND" ]
    do
      NOTFOUND=""
      for i in $WAITPORT
      do
        if [ ! -e "/sys/class/net/$i" ];then NOTFOUND="true";fi
      done
      if [ -n "$NOTFOUND" ];then sleep 1;fi
    done
  fi
# Previous work (stop the interface)
elif [ "$MODE" = "stop" ];  then
  if [ "$PHASE" = "pre-down" ]; then
    [ ! -d /sys/class/net/$IFACE ] && ip link add dev $IFACE type bridge && ip address add "$IF_ADDRESS"/"$IF_NETMASK" dev $IFACE
  elif [ "$PHASE" = "post-down" ]; then
  ip link set dev $IFACE down || exit 1
  fi
fi

all_interfaces= &&
unset all_interfaces &&
bridge_parse_ports $INTERFACES | while read i
do
  for port in $i
  do
    # We attach and configure each port of the bridge
    if [ "$MODE" = "start" ] && [ ! -d /sys/class/net/$IFACE/brif/$port ]; then
      create_vlan_port
      if [ "$IF_BRIDGE_HW" ]
      then
        KVER="$(uname -r)"
        LKVER="${KVER#*.}"
        LKVER="${LKVER%%-*}"
        LKVER="${LKVER%%.*}"
        if [ "${KVER%%.*}" -lt 3 -o "${KVER%%.*}" -eq 3 -a "$LKVER" -lt 3 ]
        then
          ip link set dev $port address $IF_BRIDGE_HW
        fi
      fi
      if [ -f /proc/sys/net/ipv6/conf/$port/disable_ipv6 ]
      then
        echo 1 > /proc/sys/net/ipv6/conf/$port/disable_ipv6
      fi
      if [ "$IF_MTU" ]
      then
        ip link set dev $port mtu "$IF_MTU"
      fi
      ip link set dev $port master $IFACE && ip link set dev $port up
    # We detach each port of the bridge
    elif [ "$MODE" = "stop" -a "$PHASE" = "post-down" ] && [ -d /sys/class/net/$IFACE/brif/$port ];  then
      ip link set dev $port down && ip link set dev $port nomaster && destroy_vlan_port
      if [ -f /proc/sys/net/ipv6/conf/$port/disable_ipv6 ]
      then
        echo 0 > /proc/sys/net/ipv6/conf/$port/disable_ipv6
      fi
    fi
  done
done

# We finish setting up the bridge
if [ "$MODE" = "start" ] ; then

  # We activate the bridge
  ip link set dev $IFACE up

# Finally we destroy the interface
elif [ "$MODE" = "stop" -a "$PHASE" = "post-down" ];  then

  ip link delete dev $IFACE

fi
