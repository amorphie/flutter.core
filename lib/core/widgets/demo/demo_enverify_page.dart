import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:neo_core/core/channel/bridge_manager.dart';

class EnverifyDemo extends StatefulWidget {
  const EnverifyDemo({super.key});
  @override
  State<StatefulWidget> createState() {
    return _EnverifyDemo();
  }
}

class _EnverifyDemo extends State<EnverifyDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Demo Enverify SDK"),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
      ),
      body: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            OutlinedButton(
              child: Text("Prepare SDK"),
              style: OutlinedButton.styleFrom(
                primary: Colors.red,
                side: BorderSide(
                  color: Colors.red,
                ),
              ),
              onPressed: () {
                print("SDK has been prepared for usage.");
                BridgeManager().prepareSDK();
              },
            ),
            OutlinedButton(
              child: Text("Start SDK"),
              style: OutlinedButton.styleFrom(
                primary: Colors.green,
                side: BorderSide(
                  color: Colors.green,
                ),
              ),
              onPressed: () {
                print("SDK has been started");
                  BridgeManager().startSDK("hasan", "gücüyener", "ib");
              },
            ),
            OutlinedButton(
              child: Text("Button 3"),
              style: OutlinedButton.styleFrom(
                primary: Colors.blue,
                side: BorderSide(
                  color: Colors.blue,
                ),
              ),
              onPressed: () {},
            ),
            OutlinedButton(
              child: Text("Button 4"),
              style: OutlinedButton.styleFrom(
                primary: Colors.orange,
                side: BorderSide(
                  color: Colors.orange,
                ),
              ),
              onPressed: () {},
            ),
            OutlinedButton(
              child: Text("Button 5"),
              style: OutlinedButton.styleFrom(
                primary: Colors.purple,
                side: BorderSide(
                  color: Colors.purple,
                ),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
