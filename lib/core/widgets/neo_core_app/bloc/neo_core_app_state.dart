/*
 * neo_core
 *
 * Created on 17/11/2023.
 * Copyright (c) 2023 Commencis. All rights reserved.
 *
 * Save to the extent permitted by law, you may not use, copy, modify,
 * distribute or create derivative works of this material or any part
 * of it without the prior written consent of Commencis.
 * Any reproduction of this material must contain this notice.
 */

part of 'neo_core_app_bloc.dart';

sealed class NeoCoreAppState extends Equatable {
  const NeoCoreAppState();
}

class NeoCoreAppInitial extends NeoCoreAppState {
  @override
  List<Object> get props => [];
}
