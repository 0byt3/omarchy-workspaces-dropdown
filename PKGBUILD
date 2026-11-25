pkgname=nier-workspaces-dropdown
pkgver=1.2.0
pkgrel=1
pkgdesc='Active-workspace dropdown widget for the Omarchy bar'
arch=('any')
url='https://github.com/0byt3/omarchy-workspaces-dropdown'
license=('MIT')
depends=('omarchy>=4.0.6' 'quickshell' 'jq' 'util-linux')
install=nier-workspaces-dropdown.install
source=('nier-workspaces-dropdown-enable' 'nier-workspaces-dropdown.install' 'manifest.json' 'Workspaces.qml' 'Model.js' 'README.md' 'LICENSE' 'monitor.svg')
sha256sums=('ddfb47408ee50715db4f79c41cf8d0205f0ec85fe6a3bfb0d8c7cea3c1af17dd'
            '1e09931fbc48bb4ed56ba8757431510dc2dc92b95f341bc5775d758895cb89c7'
            'c19bdb7eb40a377b672f13607a1a4eb3c5a641a981ffc866ffdd4b9ec82f8157'
            '442198eecbb1e5b8ade6ad0ebf22afcb8494f7f14ef1aba4b2aa8ee2b79f2dd3'
            '019742b66876135c43d699ad1898935f29b6b4b48a604f2895fff59ef789a7ce'
            '2ed0cf3ceb1b1fc19db62e5ddfbb5de9be8885b23088738b538839615bd9035b'
            '717ba1949502290f8e47688ae2e323acd06c8ca47aec9f7596b15f678c1af4a2'
            '5eb9968f63d6b311833e562d5915457a91490f9ce9db605e6744e4c36ceb24d3')
package() {
  install -Dm755 nier-workspaces-dropdown-enable "$pkgdir/usr/share/nier/bin/nier-workspaces-dropdown-enable"
  install -d "$pkgdir/usr/bin"
  ln -s /usr/share/nier/bin/nier-workspaces-dropdown-enable "$pkgdir/usr/bin/nier-workspaces-dropdown-enable"
  install -d "$pkgdir/usr/share/nier/plugins/nier.workspaces-dropdown"
  install -m644 manifest.json Workspaces.qml Model.js monitor.svg "$pkgdir/usr/share/nier/plugins/nier.workspaces-dropdown/"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
