import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// 增加Hint类型的空实现
class Hint {
  const Hint();
}

FutureOr<SentryEvent?> sentryBeforeSend(SentryEvent event, dynamic hint) {
  if (!canSendEvent(event.throwable)) return null;
  return event.copyWith(
    user: SentryUser(email: "", username: "", ipAddress: "0.0.0.0"),
  );
}

bool canSendEvent(dynamic throwable) {
  return switch (throwable) {
    UnexpectedFailure(:final error) => canSendEvent(error),
    DioException _ => false,
    SocketException _ => false,
    HttpException _ => false,
    HandshakeException _ => false,
    ExpectedFailure _ => false,
    ExpectedMeasuredFailure _ => false,
    _ => true,
  };
}

bool canLogEvent(dynamic throwable) => switch (throwable) {
      ExpectedMeasuredFailure _ => true,
      _ => canSendEvent(throwable),
    };
