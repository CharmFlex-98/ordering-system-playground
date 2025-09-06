import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/order_view_state.dart';

class OrderViewModel extends Notifier<OrderState> {
  int _currentMaxOrderId = 1;
  int _currentMaxBotId = 1;
  final Map<int, Timer> _botTaskMap = {};

  @override
  OrderState build() {
    return OrderState.empty();
  }

  void _addOrder(OrderTask orderTask) {
    state.priorityOrderListMap[orderTask.orderedBy.priority]?.add(orderTask);
    state = state.update();
  }

  void onAddOrder(Customer customer) {
    final newOrder = OrderTask(
      orderedBy: customer,
      orderId: _currentMaxOrderId++,
      taskState: TaskState.pending,
      handler: null,
    );

    _addOrder(newOrder);
    _idleBotPickUpTask();
  }

  void onAddBot() {
    final bot = Bot(employeeId: _currentMaxBotId++, isIdle: true);
    state.bots.add(bot);

    state = state.update();

    _pickUpPendingTask(bot);
  }

  void _onTaskCompleted(OrderTask orderTask, Bot botEmployee) {
    _botTaskMap.remove(botEmployee.employeeId);
    Bot newBotState = botEmployee.update(isIdle: true);
    final newTaskState = orderTask.update(taskState: TaskState.completed);

    state.priorityOrderListMap[orderTask.orderedBy.priority]?.removeWhere(
      (order) => order.orderId == orderTask.orderId,
    );
    state.completedTasks.add(newTaskState);
    state = state.update(
      bots: state.bots
          .map(
            (bot) =>
                bot.employeeId == newBotState.employeeId ? newBotState : bot,
          )
          .toList(),
    );

    _pickUpPendingTask(newBotState);
  }

  void _pickUpPendingTask(Bot botEmployee) {
    final pendingTask = state.pendingOrders.firstOrNull;

    if (pendingTask == null) return;

    _botTaskMap[botEmployee.employeeId] = Timer(Duration(seconds: 10), () {
      _onTaskCompleted(pendingTask, botEmployee);
    });

    Bot updatedBot = botEmployee.update(isIdle: false);
    OrderTask updatedTask = pendingTask.update(
      taskState: TaskState.processing,
      handler: updatedBot,
    );

    final newMap = state.priorityOrderListMap;
    newMap[updatedTask.orderedBy.priority] =
        newMap[updatedTask.orderedBy.priority]
            ?.map(
              (order) =>
                  order.orderId == updatedTask.orderId ? updatedTask : order,
            )
            .toList() ??
        [];

    state = state.update(
      bots: state.bots
          .map(
            (bot) => bot.employeeId == updatedBot.employeeId ? updatedBot : bot,
          )
          .toList(),
      priorityOrderListMap: newMap,
    );
  }

  void onRemoveNewestBot() {
    if (state.bots.isEmpty) return;

    Bot bot = state.bots.removeLast();
    state = state.update();

    Timer? onGoingTask = _botTaskMap.remove(bot.employeeId);
    onGoingTask?.cancel();

    final task = state.processingOrders
        .where((order) => order.handler?.employeeId == bot.employeeId)
        .firstOrNull;
    if (task == null) return;

    final taskToPending = task.update(taskState: TaskState.pending);
    state.priorityOrderListMap[taskToPending.orderedBy.priority] =
        state.priorityOrderListMap[taskToPending.orderedBy.priority]
            ?.map(
              (order) => order.orderId == taskToPending.orderId
                  ? taskToPending
                  : order,
            )
            .toList() ??
        [];
    state = state.update();

    _idleBotPickUpTask();
  }

  void _idleBotPickUpTask() {
    final idleBot = state.bots.firstWhereOrNull((bot) => bot.isIdle);
    if (idleBot != null) {
      _pickUpPendingTask(idleBot);
    }
  }
}

final orderStateProvider = NotifierProvider<OrderViewModel, OrderState>(
  () => OrderViewModel(),
);
