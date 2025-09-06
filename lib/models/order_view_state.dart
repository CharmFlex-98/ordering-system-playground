enum TaskState { pending, processing, completed }

enum CustomerPriority {
  /* Higher priority value means more important */
  normal(priority: 1),
  vip(priority: 2),
  returned(priority: 3);

  final int priority;

  const CustomerPriority({required this.priority});
}

class Customer {
  final CustomerPriority priority;

  const Customer({required this.priority});
}

class Bot {
  final int employeeId;
  final bool isIdle;

  Bot({required this.employeeId, required this.isIdle});

  Bot update({required bool isIdle}) {
    return Bot(employeeId: this.employeeId, isIdle: isIdle);
  }
}

class OrderTask {
  final int orderId;
  final TaskState taskState;
  final Bot? handler;
  final Customer orderedBy;

  OrderTask({
    required this.orderedBy,
    required this.orderId,
    required this.taskState,
    required this.handler,
  });

  OrderTask update({TaskState? taskState, Bot? handler}) {
    return OrderTask(
      orderedBy: orderedBy,
      orderId: orderId,
      taskState: taskState ?? this.taskState,
      handler: handler ?? this.handler,
    );
  }
}

class OrderState {
  final List<Bot> bots;
  final Map<CustomerPriority, List<OrderTask>> priorityOrderListMap;
  final List<OrderTask> completedTasks;

  const OrderState({
    required this.bots,
    required this.priorityOrderListMap,
    required this.completedTasks,
  });

  static OrderState empty() {
    return OrderState(
      bots: [],
      priorityOrderListMap: {
        CustomerPriority.returned: [],
        CustomerPriority.vip: [],
        CustomerPriority.normal: [],
      },
      completedTasks: [],
    );
  }

  get orders {
    return (priorityOrderListMap[CustomerPriority.returned] ?? []) +
        (priorityOrderListMap[CustomerPriority.vip] ?? []) +
        (priorityOrderListMap[CustomerPriority.normal] ?? []);
  }

  List<OrderTask> get pendingOrders {
    return orders.where((orders) {
      return orders.taskState == TaskState.pending;
    }).toList();
  }

  List<OrderTask> get processingOrders {
    return orders.where((orders) {
      return orders.taskState == TaskState.processing;
    }).toList();
  }

  List<OrderTask> getCompletedOrder() {
    return completedTasks;
  }

  OrderState update({
    List<Bot>? bots,
    Map<CustomerPriority, List<OrderTask>>? priorityOrderListMap,
    List<OrderTask>? completedTask,
  }) {
    return OrderState(
      bots: bots ?? this.bots,
      priorityOrderListMap: priorityOrderListMap ?? this.priorityOrderListMap,
      completedTasks: completedTask ?? this.completedTasks,
    );
  }
}