# vyos-wwan-utils

Collection of scripts and general info that may be useful for VyOS users who want to "easily" manage MBIM devices, in particular LTE modems.

The scripts were written by me in an attempt at getting VyOS to manage a Sierra Wireless EM7455 automatically.

I would say I more or less succeeded, even if relying on VyOS' load balancing feature feels like an ugly hack.

Scripts are recommended to be put in `/config/scripts`, but as long as you change the hardcoded paths in their code they should work anywhere.

## Useful resources

- https://github.com/danielewood/sierra-wireless-modems
- https://github.com/elementzonline/GSMModem/tree/master/SIM7600/mbim-set-ip

## on-load-balancing-status-change.script

As the script's name implies, it's meant to be called by the load balacing system when an interface fails or comes back online.

The script logs status changes to `/var/log/load-balancing-status.txt`, for example:

```
2020-12-10T20:52:04+01:00 wwan0 FAILED
2020-12-10T20:56:35+01:00 wwan0 ACTIVE
```

If `wwan0` fails, the script takes care of executing [restart-wwan.bash](#restart-wwanbash) as a separate process.

Please note that the script is short and simple on purpose.

From https://docs.vyos.io/en/latest/configuration/loadbalancing/index.html#script-execution:

> Blocking call with no timeout. System will become unresponsive if script does not return!

## restart-wwan.bash

Dependencies:

- **libmbim-utils** package.
- **mbim-set-ip** (see [Useful resources](#useful-resources)).

Reconnects the modem until the load balancing system reports that it's online.

The timer for a new attempt starts at 10 seconds and increases by 5 seconds every attempt, for a maximum of 60 seconds.

The scripts expects the MBIM configuration to be found at `/config/user-data/mbim-network.conf`.

## Example configuration

```
set load-balancing wan hook /config/scripts/on-load-balancing-status-change.script

set load-balancing wan interface-health wwan0 failure-count 1
set load-balancing wan interface-health wwan0 nexthop 0.0.0.0
set load-balancing wan interface-health wwan0 success-count 1

set load-balancing wan interface-health wwan0 test 10 resp-time 5
set load-balancing wan interface-health wwan0 test 10 target 1.1.1.1
set load-balancing wan interface-health wwan0 test 10 ttl-limit 1
set load-balancing wan interface-health wwan0 test 10 type ping
```

See https://docs.vyos.io/en/latest/configuration/loadbalancing for detailed instructions.

## Connecting modem at boot

Running [restart-wwan.bash](#restart-wwanbash) in `/config/scripts/vyos-postconfig-bootup.script` should work.
