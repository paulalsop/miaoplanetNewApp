import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/config_option/notifier/warp_option_notifier.dart';
import 'package:hiddify/features/config_option/overview/warp_options_widgets.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_notifier.g.dart';

@riverpod
class AddProfile extends _$AddProfile with AppLogger {
  @override
  AsyncValue<Unit?> build() {
    ref.disposeDelay(const Duration(minutes: 1));
    ref.onDispose(() {
      loggy.debug("disposing");
      _cancelToken?.cancel();
    });
    ref.listenSelf(
      (previous, next) async {
        try {
          final sharedPrefs = await ref.read(sharedPreferencesProvider.future);
          final t = ref.read(translationsProvider);
          final notification = ref.read(inAppNotificationControllerProvider);
          switch (next) {
            case AsyncData(value: final _?):
              notification.showSuccessToast(t.profile.save.successMsg);
            case AsyncError(:final error):
              if (error case ProfileInvalidUrlFailure()) {
                notification.showErrorToast(t.failure.profiles.invalidUrl);
              } else {
                notification.showErrorDialog(
                  t.presentError(error, action: t.profile.add.failureMsg),
                );
              }
          }
        } catch (e) {
          loggy.warning("Error in listenSelf: $e");
        }
      },
    );
    return const AsyncData(null);
  }

  ProfileRepository? _getProfileRepo() {
    try {
      return ref.read(profileRepositoryProvider).requireValue;
    } catch (e) {
      loggy.warning("获取ProfileRepository失败: $e");
      return null;
    }
  }

  CancelToken? _cancelToken;

  Future<void> add(String rawInput) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    
    // 添加重试逻辑
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        state = await AsyncValue.guard(
          () async {
            loggy.debug("尝试添加配置文件 (尝试 ${retryCount + 1}/${maxRetries})");
            
            // 安全地获取ProfileRepository
            final repo = _getProfileRepo();
            if (repo == null) {
              loggy.debug("等待ProfileRepository初始化...");
              await Future.delayed(Duration(milliseconds: 500));
              throw Exception("ProfileRepository尚未初始化，稍后重试");
            }
            
            // 安全地获取activeProfile
            ProfileEntity? activeProfile;
            try {
              activeProfile = await ref.read(activeProfileProvider.future);
            } catch (e) {
              loggy.debug("获取activeProfile失败: $e");
            }
            
            // 安全地获取markNewProfileActive设置
            bool markAsActive = true;
            try {
              if (activeProfile != null) {
                final prefs = await ref.read(sharedPreferencesProvider.future);
                markAsActive = prefs.getBool("mark_new_profile_active") ?? true;
              }
            } catch (e) {
              loggy.debug("获取markNewProfileActive设置失败: $e");
              // 默认使用true
            }
            
            final TaskEither<ProfileFailure, Unit> task;
            
            if (LinkParser.parse(rawInput) case (final link)?) {
              loggy.debug("添加配置，URL: [${link.url}]");
              task = repo.addByUrl(
                link.url,
                markAsActive: markAsActive,
                cancelToken: _cancelToken = CancelToken(),
              );
            } else if (LinkParser.protocol(rawInput) case (final parsed)?) {
              loggy.debug("添加配置，内容");
              var name = parsed.name;
              var oldItem = await repo.getByName(name);
              if (name == "Hiddify WARP" && oldItem != null) {
                repo.deleteById(oldItem.id).run();
              }
              while (await repo.getByName(name) != null) {
                name += '${randomInt(0, 9).run()}';
              }
              task = repo.addByContent(
                parsed.content,
                name: name,
                markAsActive: markAsActive,
              );
            } else {
              loggy.debug("无效内容");
              throw const ProfileInvalidUrlFailure();
            }
            
            return task.match(
              (err) {
                loggy.warning("添加配置失败", err);
                throw err;
              },
              (_) {
                loggy.info(
                  "成功添加配置，标记为活跃? [$markAsActive]",
                );
                return unit;
              },
            ).run();
          },
        );
        
        // 如果成功或出现无法重试的错误，则跳出循环
        if (state is AsyncData || state.error is ProfileInvalidUrlFailure) {
          break;
        }
        
        // 如果是其他错误，进行重试
        retryCount++;
        if (retryCount < maxRetries) {
          loggy.debug("添加配置失败，将在1秒后重试 (${retryCount}/${maxRetries})");
          await Future.delayed(Duration(seconds: 1));
        }
      } catch (e) {
        loggy.warning("添加配置时发生异常: $e");
        retryCount++;
        if (retryCount < maxRetries) {
          loggy.debug("将在1秒后重试 (${retryCount}/${maxRetries})");
          await Future.delayed(Duration(seconds: 1));
        } else {
          state = AsyncError(e is ProfileFailure ? e : ProfileUnexpectedFailure(e), StackTrace.current);
        }
      }
    }
  }

  Future<void> check4Warp(String rawInput) async {
    for (final line in rawInput.split("\n")) {
      if (line.toLowerCase().startsWith("warp://")) {
        final _prefs = ref.read(sharedPreferencesProvider).requireValue;
        final _warp = ref.read(warpOptionNotifierProvider.notifier);

        final consent = false &&
            (_prefs.getBool(WarpOptionNotifier.warpConsentGiven) ?? false);

        final t = ref.read(translationsProvider);
        final notification = ref.read(inAppNotificationControllerProvider);

        if (!consent) {
          final agreed = await showDialog<bool>(
            context: RootScaffold.stateKey.currentContext!,
            builder: (context) => const WarpLicenseAgreementModal(),
          );

          if (agreed ?? false) {
            await _prefs.setBool(WarpOptionNotifier.warpConsentGiven, true);
            final toast = notification.showInfoToast(
                t.profile.add.addingWarpMsg,
                duration: const Duration(milliseconds: 100));
            toast?.pause();
            await _warp.generateWarpConfig();
            toast?.start();
          } else {
            return;
          }
        }

        final accountId = _prefs.getString("warp2-account-id");
        final accessToken = _prefs.getString("warp2-access-token");
        final hasWarp2Config = accountId != null && accessToken != null;

        if (!hasWarp2Config || true) {
          final toast = notification.showInfoToast(t.profile.add.addingWarpMsg,
              duration: const Duration(milliseconds: 100));
          toast?.pause();
          await _warp.generateWarp2Config();
          toast?.start();
        }
      }
    }
  }
}

@riverpod
class UpdateProfile extends _$UpdateProfile with AppLogger {
  @override
  AsyncValue<Unit?> build(String id) {
    ref.disposeDelay(const Duration(minutes: 1));
    ref.listenSelf(
      (previous, next) {
        final t = ref.read(translationsProvider);
        final notification = ref.read(inAppNotificationControllerProvider);
        switch (next) {
          case AsyncData(value: final _?):
            notification.showSuccessToast(t.profile.update.successMsg);
          case AsyncError(:final error):
            notification.showErrorDialog(
              t.presentError(error, action: t.profile.update.failureMsg),
            );
        }
      },
    );
    return const AsyncData(null);
  }

  ProfileRepository get _profilesRepo =>
      ref.read(profileRepositoryProvider).requireValue;

  Future<void> updateProfile(RemoteProfileEntity profile) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    await ref.read(hapticServiceProvider.notifier).lightImpact();
    state = await AsyncValue.guard(
      () async {
        return await _profilesRepo.updateSubscription(profile).match(
          (err) {
            loggy.warning("failed to update profile", err);
            throw err;
          },
          (_) async {
            loggy.info(
              'successfully updated profile, was active? [${profile.active}]',
            );

            await ref.read(activeProfileProvider.future).then((active) async {
              if (active != null && active.id == profile.id) {
                await ref
                    .read(connectionNotifierProvider.notifier)
                    .reconnect(profile);
              }
            });
            return unit;
          },
        ).run();
      },
    );
  }
}
