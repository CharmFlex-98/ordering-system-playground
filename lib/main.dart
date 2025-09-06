import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ordering_system/orderViewModel.dart';

import 'models/order_view_state.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderStateProvider);
    final viewModel = ref.read(orderStateProvider.notifier);

    final idleBots = state.bots
        .where((bot) => bot.isIdle)
        .toList(growable: false);

    final processingOrders = state.processingOrders;
    final pendingOrders = state.pendingOrders;
    final completedOrders = state.completedTasks;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Order System"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                RestaurantConditionLane<OrderTask>(
                  items: processingOrders,
                  areaText: "PENDING (processing)",
                  laneBuilder: (child) => ProcessingOrderCard(order: child)
                ),
                SizedBox(width: 8,),
                RestaurantConditionLane<Bot>(
                  items: idleBots,
                  areaText: "IDLE BOTs",
                  laneBuilder: (child) => BotCard(bot: child),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 5,
            child: Container(
              color: Colors.grey,
              child: Column(
                children: [
                  OrderLane(orders: pendingOrders),
                  Divider(),
                  Text(style: TextStyle(fontSize: 11), "PENDING"),
                  Text(style: TextStyle(fontSize: 11), "COMPLETED"),
                  Divider(),
                  OrderLane(orders: completedOrders),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                MyButton(text: "+ bot", onClicked: viewModel.onAddBot),
                MyButton(text: "- bot", onClicked: viewModel.onRemoveNewestBot),
                MyButton(
                  text: "New VIP order",
                  onClicked: () => viewModel.onAddOrder(
                    Customer(priority: CustomerPriority.vip),
                  ),
                ),
                MyButton(
                  text: "New Normal order",
                  onClicked: () => viewModel.onAddOrder(
                    Customer(priority: CustomerPriority.normal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProcessingOrderCard extends StatelessWidget {
  final OrderTask order;

  const ProcessingOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final botId = order.handler?.employeeId ?? -1;

    String priority = order.orderedBy.priority == CustomerPriority.normal
        ? "Normal"
        : "VIP";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: ListTile(
        leading: CircularProgressIndicator(),
        title: Text("Order ${order.orderId}, $priority"),
        subtitle: Text("Bot: ${botId}"),
      ),
    );
  }
}

class BotCard extends StatelessWidget {
  final Bot bot;

  const BotCard({super.key, required this.bot});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: ListTile(
        title: const Text("Bot"),
        subtitle: Text("id: ${bot.employeeId}"),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderTask order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    String customer = order.orderedBy.priority == CustomerPriority.vip
        ? "VIP"
        : "Normal";
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(5),
      child: Column(
        children: [
          const Icon(Icons.task),
          const Text("Order"),
          Text("id: ${order.orderId}, type: $customer"),
        ],
      ),
    );
  }
}

class OrderLane extends StatelessWidget {
  final List<OrderTask> orders;

  const OrderLane({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: orders.length,
          itemBuilder: (context, index) {
            return OrderCard(order: orders[index]);
          },
        ),
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  final VoidCallback onClicked;
  final String text;

  const MyButton({super.key, required this.text, required this.onClicked});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onClicked();
      },
      child: Text(style: TextStyle(fontSize: 11), text),
    );
  }
}

class RestaurantConditionLane<T> extends StatelessWidget {
  final String areaText;
  final Widget Function(T)  laneBuilder;
  final List<T> items;

  const RestaurantConditionLane({
    super.key,
    required this.items,
    required this.areaText,
    required this.laneBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      color: Colors.grey[200],
      child: Column(
        children: [
          Padding(padding: EdgeInsets.all(8.0), child: Text(areaText)),
          Expanded(child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return laneBuilder(items[index]);
            },
          ),),
        ],
      ),
    ));
  }
}
