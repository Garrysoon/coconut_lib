part of '../../coconut_lib.dart';

class NetworkType {
  final String _name;
  final bool _isTestnet;

  /// Check if it is testnet
  bool get isTestnet => _isTestnet;

  NetworkType(this._name, this._isTestnet);

  /// @nodoc
  @override
  String toString() {
    return _name;
  }

  @override
  int get hashCode => _name.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is NetworkType) {
      return _name == other._name;
    }
    return false;
  }

  /// Get the current network
  static NetworkType get currentNetwork => _currentNetwork;

  /// Mainnet
  static NetworkType mainnet = NetworkType('mainnet', false);

  /// Testnet
  static NetworkType testnet = NetworkType('testnet', true);

  /// Regtest
  static NetworkType regtest = NetworkType('regtest', true);

  /// Get all network values
  static List<NetworkType> get values => [mainnet, testnet, regtest];

  static NetworkType _currentNetwork = NetworkType.testnet;

  /// Set network type
  static setNetworkType(NetworkType networkType) {
    _currentNetwork = networkType;
  }

  /// Get network by name (mainnet, testnet, regtest)
  static NetworkType getNetworkType(String network) {
    switch (network) {
      case 'mainnet':
        return mainnet;
      case 'testnet':
        return testnet;
      case 'regtest':
        return regtest;
      default:
        throw Exception('Invalid network type');
    }
  }
}
