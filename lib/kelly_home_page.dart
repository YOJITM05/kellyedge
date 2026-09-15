import 'package:flutter/material.dart';
import 'auth_service.dart';

class KellyHomePage extends StatefulWidget {
  const KellyHomePage({super.key});

  @override
  State<KellyHomePage> createState() => _KellyHomePageState();
}

class _KellyHomePageState extends State<KellyHomePage> {
  final AuthService authService = AuthService();

  // ---------------- Controllers (UI layer) ----------------
  final TextEditingController winProbController = TextEditingController();
  final TextEditingController ratioController = TextEditingController();
  final TextEditingController bankrollController = TextEditingController();

  // ---------------- State (UI layer) ----------------
  String errorMessage = '';
  double? kellyFraction;
  String? riskCategory;
  double? suggestedStake;

  // ---------------- History ----------------
  // In-memory only: no external database. Newest entry first.
  final List<Map<String, dynamic>> history = [];

  // =========================================================
  // CALCULATION LAYER
  // f* = W - (1 - W) / R
  // =========================================================
  double calculateKellyFraction(double W, double R) {
    return W - (1 - W) / R;
  }

  // =========================================================
  // DECISION LAYER
  // =========================================================
  String getRiskCategory(double fraction) {
    if (fraction <= 0) {
      return 'No Edge – Avoid Bet';
    } else if (fraction <= 0.10) {
      return 'Conservative – Small Bet';
    } else if (fraction <= 0.25) {
      return 'Moderate – Balanced Bet';
    } else {
      return 'Aggressive – High Bet';
    }
  }

  Color getRiskColor(String category) {
    if (category.startsWith('No Edge')) {
      return Colors.red;
    } else if (category.startsWith('Conservative')) {
      return Colors.orange;
    } else if (category.startsWith('Moderate')) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  double calculateSuggestedStake(double fraction, double bankroll) {
    if (fraction <= 0) {
      return 0;
    }
    return fraction * bankroll;
  }

  // =========================================================
  // INPUT VALIDATION + ORCHESTRATION
  // =========================================================
  void onCalculatePressed() {
    final String winText = winProbController.text.trim();
    final String ratioText = ratioController.text.trim();
    final String bankrollText = bankrollController.text.trim();

    final double? W = double.tryParse(winText);
    final double? R = double.tryParse(ratioText);
    final double? bankroll = double.tryParse(bankrollText);

    if (W == null || R == null || bankroll == null) {
      setState(() {
        errorMessage = 'Please enter valid numbers in all fields.';
        kellyFraction = null;
        riskCategory = null;
        suggestedStake = null;
      });
      return;
    }

    if (W <= 0 || W >= 1) {
      setState(() {
        errorMessage = 'Win probability must be between 0 and 1.';
        kellyFraction = null;
        riskCategory = null;
        suggestedStake = null;
      });
      return;
    }

    if (R <= 0) {
      setState(() {
        errorMessage = 'Win/Loss ratio must be greater than 0.';
        kellyFraction = null;
        riskCategory = null;
        suggestedStake = null;
      });
      return;
    }

    if (bankroll <= 0) {
      setState(() {
        errorMessage = 'Bankroll must be greater than 0.';
        kellyFraction = null;
        riskCategory = null;
        suggestedStake = null;
      });
      return;
    }

    final double fraction = calculateKellyFraction(W, R);
    final String category = getRiskCategory(fraction);
    final double stake = calculateSuggestedStake(fraction, bankroll);

    setState(() {
      errorMessage = '';
      kellyFraction = fraction;
      riskCategory = category;
      suggestedStake = stake;
      history.insert(0, {
        'W': W,
        'R': R,
        'bankroll': bankroll,
        'fraction': fraction,
        'category': category,
        'stake': stake,
      });
    });
  }

  @override
  void dispose() {
    winProbController.dispose();
    ratioController.dispose();
    bankrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // UI LAYER
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final String? email = authService.currentUser?.email;
    return Scaffold(
      appBar: AppBar(
        title: const Text('KellyEdge – Position Sizing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (email != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Signed in as $email',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              const Text(
                'Kelly Criterion Calculator',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: winProbController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Win Probability (W), e.g. 0.55',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ratioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Win/Loss Ratio (R), e.g. 2.0',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankrollController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bankroll (₹), e.g. 10000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onCalculatePressed,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Calculate'),
                ),
              ),
              const SizedBox(height: 20),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.red)),
              if (kellyFraction != null) buildResultCard(),
              const SizedBox(height: 24),
              buildExplanationPanel(),
              const SizedBox(height: 24),
              if (history.isNotEmpty) buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildResultCard() {
    final Color color = getRiskColor(riskCategory!);
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelly Fraction: ${(kellyFraction! * 100).toStringAsFixed(2)}%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              riskCategory!,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Suggested Stake: ₹${suggestedStake!.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Self-documenting explanation panel — purely static content.
  Widget buildExplanationPanel() {
    return ExpansionTile(
      title: const Text(
        'What do these categories mean?',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      children: const [
        ListTile(
          leading: Icon(Icons.circle, color: Colors.red, size: 14),
          title: Text('No Edge – Avoid Bet'),
          subtitle: Text('Kelly fraction ≤ 0%. No statistical edge; stake is ₹0.'),
        ),
        ListTile(
          leading: Icon(Icons.circle, color: Colors.orange, size: 14),
          title: Text('Conservative – Small Bet'),
          subtitle: Text('Kelly fraction between 0% and 10%. A small edge.'),
        ),
        ListTile(
          leading: Icon(Icons.circle, color: Colors.blue, size: 14),
          title: Text('Moderate – Balanced Bet'),
          subtitle: Text('Kelly fraction between 10% and 25%. A solid edge.'),
        ),
        ListTile(
          leading: Icon(Icons.circle, color: Colors.green, size: 14),
          title: Text('Aggressive – High Bet'),
          subtitle: Text('Kelly fraction above 25%. Strong edge, high volatility.'),
        ),
      ],
    );
  }

  // In-memory calculation history — ListView.builder's internal
  // iteration renders each row; that's Flutter's own rendering
  // machinery, not a hand-written loop in the business logic.
  Widget buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Calculations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final entry = history[index];
            final Color color = getRiskColor(entry['category'] as String);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(Icons.circle, color: color, size: 14),
                title: Text(
                  '${((entry['fraction'] as double) * 100).toStringAsFixed(2)}% '
                  '— ${entry['category']}',
                ),
                subtitle: Text(
                  'W=${entry['W']}, R=${entry['R']}, Bankroll=₹${entry['bankroll']} '
                  '→ Stake ₹${(entry['stake'] as double).toStringAsFixed(2)}',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
