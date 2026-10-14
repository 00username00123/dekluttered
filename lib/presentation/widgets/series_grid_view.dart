import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klutter/business_logic/cubit/series_list_cubit.dart';
import 'package:klutter/presentation/widgets/series_card.dart';

class SeriesGridView extends StatelessWidget {
  final SeriesListReady state;
  const SeriesGridView(
    this.state, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int totalPages = state.seriesPage.totalPages ?? 1;
    final int currentPage = state.seriesPage.number ?? 0;
    const Color amber = Color(0xFFE5A614);

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          if (totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E1E1E)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: state.seriesPage.first == true ? Colors.white24 : amber,
                    onPressed: state.seriesPage.first == true
                        ? null
                        : () => context
                            .read<SeriesListCubit>()
                            .getSeriesPage(currentPage - 1),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Page ${currentPage + 1} of $totalPages",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: const Color(0xFF161616),
                        ),
                        child: DropdownButton<int>(
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.arrow_drop_down, color: amber),
                          value: currentPage,
                          onChanged: (value) {
                            if (value != null) {
                              context.read<SeriesListCubit>().getSeriesPage(value);
                            }
                          },
                          items: Iterable<int>.generate(totalPages)
                              .map<DropdownMenuItem<int>>((e) =>
                                  DropdownMenuItem<int>(
                                    value: e,
                                    child: Text(
                                      (e + 1).toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: state.seriesPage.last == true ? Colors.white24 : amber,
                    onPressed: state.seriesPage.last == true
                        ? null
                        : () => context
                            .read<SeriesListCubit>()
                            .getSeriesPage(currentPage + 1),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                mainAxisExtent: 240,
                maxCrossAxisExtent: 140,
              ),
              itemCount: state.seriesPage.content!.length,
              itemBuilder: (context, index) {
                return SeriesCard(
                  state.seriesPage.content!.elementAt(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
