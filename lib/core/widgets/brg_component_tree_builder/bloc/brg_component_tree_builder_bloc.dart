import 'package:burgan_core/core/network/models/neo_response.dart';
import 'package:burgan_core/core/widgets/brg_component_tree_builder/network/i_components_network_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'brg_component_tree_builder_event.dart';
part 'brg_component_tree_builder_state.dart';

class BrgComponentTreeBuilderBloc extends Bloc<BrgComponentTreeBuilderEvent, BrgComponentTreeBuilderState> {
  final IComponentsNetworkManager networkManager;

  BrgComponentTreeBuilderBloc(this.networkManager) : super(BrgComponentTreeBuilderStateLoading()) {
    on<BrgComponentTreeBuilderEventFetchComponents>((event, emit) async {
      try {
        NeoResponse response = await networkManager.fetchPageComponentsByPageId(
          event.pageId,
        );
        if (response.isSuccess) {
          emit(BrgComponentTreeBuilderStateLoaded(componentsMap: ((response as NeoSuccessResponse).data)));
        } else {
          emit(
            BrgComponentTreeBuilderStateError(
              // TODO: Select error message based on current language
              errorMessage: (response as NeoErrorResponse).error.messages.firstOrNull?.title ?? "",
            ),
          );
        }
      } on Exception catch (e) {
        emit(BrgComponentTreeBuilderStateError(errorMessage: e.toString()));
      }
    });
  }
}
