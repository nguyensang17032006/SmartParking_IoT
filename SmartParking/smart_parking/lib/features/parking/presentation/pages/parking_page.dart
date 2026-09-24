import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/parking_bloc.dart';
import '../bloc/parking_state.dart';

class ParkingPage extends StatelessWidget {
  const ParkingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Parking')),

      body: BlocBuilder<ParkingBloc, ParkingState>(
        builder: (context, state) {
          if (state is ParkingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ParkingLoaded) {
            return GridView.builder(
              itemCount: state.slots.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),

              itemBuilder: (context, index) {
                final slot = state.slots[index];

                return Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(slot.code),

                      const SizedBox(height: 10),

                      Icon(
                        Icons.local_parking,
                        size: 60,
                        color: slot.occupied ? Colors.red : Colors.green,
                      ),

                      Text(slot.occupied ? 'Có xe' : 'Trống'),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
