import 'package:neo_core/core/network/models/neo_response.dart';
import 'package:neo_core/core/widgets/neo_component_tree_builder/network/i_components_network_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'neo_component_tree_builder_event.dart';
part 'neo_component_tree_builder_state.dart';

class NeoComponentTreeBuilderBloc extends Bloc<NeoComponentTreeBuilderEvent, NeoComponentTreeBuilderState> {
  final IComponentsNetworkManager networkManager;

  NeoComponentTreeBuilderBloc(this.networkManager) : super(NeoComponentTreeBuilderStateLoading()) {
    on<NeoComponentTreeBuilderEventFetchComponents>((event, emit) async {
      try {
        NeoResponse response = await networkManager.fetchPageComponentsByPageId(
          event.pageId,
        );
        if (response.isSuccess) {
          emit(NeoComponentTreeBuilderStateLoaded(componentsMap: ((response as NeoSuccessResponse).data)));
        } else {
          emit(
            NeoComponentTreeBuilderStateError(
              // TODO: Select error message based on current language
              errorMessage: (response as NeoErrorResponse).error.messages.firstOrNull?.title ?? "",
            ),
          );
        }
      } on Exception catch (e) {
        emit(NeoComponentTreeBuilderStateError(errorMessage: e.toString()));
      }
    });
  }
}
