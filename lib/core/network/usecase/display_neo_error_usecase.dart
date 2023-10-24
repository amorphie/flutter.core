import 'package:burgan_core/burgan_core.dart';
import 'package:burgan_core/core/network/models/neo_error_display_method.dart';
import 'package:flutter/material.dart';

class DisplayNeoErrorUseCase {
  call(NeoError neoError, BuildContext context, String languageCode) {
    if (neoError.displayMode == NeoErrorDisplayMethod.popup) {
      _displayDialog(neoError, context, languageCode);
    }
    // TODO: Handle other display methods
  }

  _displayDialog(NeoError neoError, BuildContext context, String languageCode) {
    final localizedError = neoError.getErrorMessageByLanguageCode(languageCode);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizedError?.title ?? ""),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(localizedError?.subtitle ?? ""),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'), // STOPSHIP: Get close button text from NeoError
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
