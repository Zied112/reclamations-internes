import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/reclamation_service.dart';
import 'reclamation.dart';
import 'package:intl/intl.dart';

class ManagerStatsDashboard extends StatefulWidget {
  @override
  _ManagerStatsDashboardState createState() => _ManagerStatsDashboardState();
}

class _ManagerStatsDashboardState extends State<ManagerStatsDashboard> with SingleTickerProviderStateMixin {
  late Future<List<Reclamation>> _reclamations;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _reclamations = ReclamationService.getReclamations();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(String department, int count, int total) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(department, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: count / total,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 4),
            Text('$count réclamations ($percentage%)', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Reclamation>>(
      future: _reclamations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucune donnée de réclamation.'));
        }

        final data = snapshot.data!;
        final total = data.length;
        final statusCounts = {
          'New': data.where((r) => r.status == 'New').length,
          'In Progress': data.where((r) => r.status == 'In Progress').length,
          'Done': data.where((r) => r.status == 'Done').length,
        };

        final now = DateTime.now();
        final thisMonth = DateTime(now.year, now.month);
        final lastMonth = DateTime(now.year, now.month - 1);
        int doneThisMonth = data.where((r) => r.status == 'Done' && r.updatedAt.isAfter(thisMonth)).length;
        int doneLastMonth = data.where((r) => r.status == 'Done' && r.updatedAt.isAfter(lastMonth) && r.updatedAt.isBefore(thisMonth)).length;
        double percentChange = doneLastMonth == 0 ? 100 : ((doneThisMonth - doneLastMonth) / doneLastMonth * 100);

        final durations = data.where((r) => r.status == 'Done').map((r) => r.updatedAt.difference(r.createdAt).inHours).toList();
        double avgHours = durations.isNotEmpty ? durations.reduce((a, b) => a + b) / durations.length : 0;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tableau de bord des statistiques',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 24),
                
                // Cartes de statistiques principales
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard('Nouvelles', statusCounts['New'].toString(), Icons.new_releases, Colors.blue),
                    _buildStatCard('En cours', statusCounts['In Progress'].toString(), Icons.pending_actions, Colors.orange),
                    _buildStatCard('Terminées', statusCounts['Done'].toString(), Icons.check_circle, Colors.green),
                    _buildStatCard('Durée moyenne', '${avgHours.toStringAsFixed(1)} heures', Icons.timer, Colors.purple),
                  ],
                ),
                SizedBox(height: 24),

                // Graphique circulaire
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Distribution des réclamations',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: statusCounts['New']!.toDouble(),
                                  color: Colors.blue,
                                  title: 'New\n${((statusCounts['New']!/total)*100).toStringAsFixed(1)}%',
                                  radius: 60,
                                  titleStyle: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: statusCounts['In Progress']!.toDouble(),
                                  color: Colors.orange,
                                  title: 'En cours\n${((statusCounts['In Progress']!/total)*100).toStringAsFixed(1)}%',
                                  radius: 60,
                                  titleStyle: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                PieChartSectionData(
                                  value: statusCounts['Done']!.toDouble(),
                                  color: Colors.green,
                                  title: 'Terminées\n${((statusCounts['Done']!/total)*100).toStringAsFixed(1)}%',
                                  radius: 60,
                                  titleStyle: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Évolution mensuelle
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Évolution mensuelle',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'Ce mois',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                Text(
                                  doneThisMonth.toString(),
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Mois dernier',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                Text(
                                  doneLastMonth.toString(),
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  'Évolution',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                Text(
                                  '${percentChange.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: percentChange >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Top départements
                Text(
                  'Top départements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                ..._topDepartments(data, 3).map((e) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: _buildDepartmentCard(e.key, e.value, total),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  List<MapEntry<String, int>> _topDepartments(List<Reclamation> data, int topN) {
    final Map<String, int> deptCount = {};
    for (var r in data) {
      for (var dept in r.departments) {
        deptCount[dept] = (deptCount[dept] ?? 0) + 1;
      }
    }
    final sorted = deptCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topN).toList();
  }
} 