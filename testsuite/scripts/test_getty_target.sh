#!/bin/sh

set -e

sleep 10

systemctl is-active getty.target
