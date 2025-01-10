part of '../../../coconut_lib.dart';

class RecommendedFee {
  final int _fastestFee;
  final int _halfHourFee;
  final int _hourFee;
  final int _economyFee;
  final int _minimumFee;

  RecommendedFee(this._fastestFee, this._halfHourFee, this._hourFee,
      this._economyFee, this._minimumFee);

  get fastestFee => _fastestFee;

  get halfHourFee => _halfHourFee;

  get hourFee => _hourFee;

  get economyFee => _economyFee;

  get minimumFee => _minimumFee;

  factory RecommendedFee.fromJson(Map<String, dynamic> json) {
    return RecommendedFee(
      json['fastestFee'] as int,
      json['halfHourFee'] as int,
      json['hourFee'] as int,
      json['economyFee'] as int,
      json['minimumFee'] as int,
    );
  }
}

class MempoolTransactionStatus {
  final bool confirmed;
  final int blockHeight;
  final String blockHash;
  final int blockTime;

  MempoolTransactionStatus(
      this.confirmed, this.blockHeight, this.blockHash, this.blockTime);

  factory MempoolTransactionStatus.fromJson(Map<String, dynamic> json) {
    return MempoolTransactionStatus(
      json['confirmed'] as bool,
      json['block_height'] as int,
      json['block_hash'] as String,
      json['block_time'] as int,
    );
  }
}
