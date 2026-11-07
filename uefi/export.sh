#!/bin/bash
# Save the mondrian platform from Mu-Silicium/ into files/ here (uefi/export.sh runs this; HakiOS's own changes are uefi/'s).
set -e
cd "$(dirname "$(readlink -f "$0")")"
MU=${MU:-../../../Mu-Silicium}
rm -rf files
mkdir -p files/Resources/Configs files/Resources/DTBs files/Platforms/Xiaomi files/Binaries
cp -r $MU/Platforms/Xiaomi/mondrianPkg files/Platforms/Xiaomi/
cp $MU/Resources/Configs/mondrian.toml files/Resources/Configs/
cp $MU/Resources/DTBs/mondrian.dtb files/Resources/DTBs/
cp -r $MU/Binaries/mondrian files/Binaries/
find files -name __pycache__ -prune -exec rm -rf {} +
echo "devices/mondrian/uefi/export.sh: $(find files -type f | wc -l) files"
