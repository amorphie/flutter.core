import 'package:burgan_core/core/network/models/neo_response.dart';
import 'package:burgan_core/core/util/extensions/string_extensions.dart';
import 'package:burgan_core/core/widgets/brg_component_tree_builder/network/i_components_network_manager.dart';
import 'package:burgan_core/core/widgets/brg_component_tree_builder/network/models/neo_page_components_response.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'brg_component_tree_builder_event.dart';
part 'brg_component_tree_builder_state.dart';

class BrgComponentTreeBuilderBloc extends Bloc<BrgComponentTreeBuilderEvent, BrgComponentTreeBuilderState> {
  final IComponentsNetworkManager networkManager;

  BrgComponentTreeBuilderBloc(this.networkManager) : super(BrgComponentTreeBuilderStateLoading()) {
    on<BrgComponentTreeBuilderEventFetchComponents>((event, emit) async {
      try {
        NeoResponse<NeoPageComponentsResponse> response = await networkManager.fetchPageComponentsByPageId(
          event.pageId,
        );
        if (response.isSuccess) {
          emit(BrgComponentTreeBuilderStateLoaded(componentsMap: ((response as NeoSuccess).data).componentsMap));
        } else {
          emit(BrgComponentTreeBuilderStateError(errorMessage: (response as NeoError).error.message.orEmpty));
        }
      } on Exception catch (e) {
        emit(BrgComponentTreeBuilderStateError(errorMessage: e.toString()));
      }
    });
  }
}
