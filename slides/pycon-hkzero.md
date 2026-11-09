---
marp: true
theme: default
paginate: true
backgroundColor: #0d1720
color: #eeeae1
style: |
  section {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang TC", sans-serif;
    background: linear-gradient(135deg, #080f17 0%, #0d1720 65%, #14212c 100%);
    color: #eeeae1;
    padding: 48px 64px;
  }
  h1, h2, h3 {
    color: #ffffff;
    letter-spacing: 1px;
  }
  h1 {
    border-left: 6px solid #bb423b;
    padding-left: 18px;
    font-size: 1.85em;
  }
  h2 {
    border-bottom: 1px solid #3d5869;
    padding-bottom: 10px;
    font-size: 1.45em;
  }
  code {
    background: #14212c;
    color: #a5d6ff;
    padding: 2px 6px;
    border-radius: 3px;
  }
  pre {
    background: #070d13 !important;
    border: 1px solid #3d5869;
    border-left: 4px solid #38c172;
    border-radius: 4px;
  }
  blockquote {
    background: #14212c;
    border-left: 4px solid #f1b748;
    padding: 12px 20px;
    color: #cdd9df;
  }
  strong {
    color: #f2d0a0;
  }
  a {
    color: #56b6c2;
  }
---

<!-- _backgroundImage: "linear-gradient(rgba(8,15,23,0.78), rgba(13,23,32,0.92)), url('../hkzero/assets/illustrations/og-hong-kong-zero-v3.jpg')" -->

# 從港域時空到 Kubernetes：將香港遊戲世界化身雲原生學習平台

**From Hong Kong Zero to Kubernetes: Turning a 3D Hong Kong Game World into a Cloud-Native Learning Platform with Python & `pytest`**

- **Speaker:** Cyrus Wong (HKIIT / VTC)
- **Platform:** `k8s-game-platform` & `hkzero-k8s`
- **Special Thanks:** Arthur & the Hong Kong Zero team (`hongkongzero.com`)

---

## MISSION 01 // Why Traditional DevOps Labs & Exams Fail

- **Terminal Fatigue:** Staring at broken YAML and `CrashLoopBackOff` errors demotivates beginners.
- **Paper Exams Miss the Mark:** Multiple-choice questions cannot measure real-world `kubectl` troubleshooting under pressure.
- **Manual Grading Doesn't Scale:** Instructors cannot manually inspect 100 live student Kubernetes clusters in real time.
- **Static Labs Invite Copying:** Hardcoded instructions let one student share the answer YAML with the whole class.

> **The Vision:** What if every monster you defeat in 3D Causeway Bay triggers a live, anti-cheating Python `pytest` inspection of your Kubernetes cluster?

---

<!-- _backgroundImage: "linear-gradient(rgba(8,15,23,0.82), rgba(13,23,32,0.94)), url('../hkzero/assets/illustrations/district-causeway-bay-v1.jpg')" -->

## MISSION 02 // Enter Hong Kong Zero (港域時空)

1. **3D WebGL Hong Kong Streets:** Students battle through Causeway Bay (SOGO), Mong Kok, and Tsim Sha Tsui in their browser.
2. **Configurable Check Probability:** Players choose a per-kill K8s check chance (10%–100%, default **50%**).
3. **Player-Caused Kill Hook (`window.onMonsterKilled`):**
   - Freezes the WebGL loop and unlocks the mouse pointer.
   - Displays a **Tactical Cyberpunk HUD Overlay** (`k8s-overlay.css`).
   - Sends a JSON grading request over an **AWS API Gateway WebSocket**.

---

## LIVE DEMO // Client-to-Python WebSocket Bridge

```javascript
// hkzero/k8s-bridge.js (Lines 639–653 & 214–229)
window.onMonsterKilled = function (enemy, context = {}) {
  if (context.playerKill === false) return;
  if (isChecking || pendingTriggers.some(t => t.actionType === 'kill-thing')) return;
  if (Math.random() >= killCheckChance) return;
  sendTrigger('kill-thing', enemy);
};

// Inside flushTriggerQueue():
pauseGame(); // Freeze 3D WebGL game & exit pointer lock
showRunningState(`Triggered by ${trigger.actionType}. Connecting to Kubernetes test cluster...`);
ws.send(JSON.stringify({ action: 'talk', apiKey: config.apiKey, game: config.game, npc: config.npc }));
```

> **3 Tactical HUD States:** 🟡 `RUNNING` (Spinner) $\rightarrow$ 🔴 `FAILED` (S3 Pytest HTML Report) $\rightarrow$ 🟢 `COMPLETED` (Unpause & Score!)

---

## Why We Moved from AJAX to WebSocket + Lambda Durable Functions

| Dimension | Previous AWS Game (AJAX) | Kubernetes Game (`k8s-game-platform`) |
| :--- | :--- | :--- |
| **What We Grade** | Fast AWS SDK metadata (`s3.get_bucket_policy`, `ec2.describe_*`) | Live K8s workloads: image pulls, Pod scheduling, ReadinessProbes & chaos |
| **Execution Time** | **100–800ms** (single `boto3` API call) | **15–60+ seconds** (chains `setup` $\rightarrow$ `ready` or `challenge` $\rightarrow$ `check`) |
| **Transport Limit** | Fits easily inside synchronous HTTP `fetch('/task')` | ❌ Crashes into API Gateway's **29s HTTP timeout** (`504 Gateway Timeout`) |
| **Our Solution** | Simple REST Request/Response | ✅ **WebSocket Ingest (`<100ms`) + `@durable_execution` + Live Phase Push** |

---

## Code Proof: Why K8s Breaks 29s AJAX & How Durable Lambda Solves It

**1. Why K8s Takes 15–120s (`681_deployment_self_healing_beginner`):**
```python
# Phase 04 (test_04_challenge.py): Delete a live Pod to trigger ReplicaSet healing!
run_kubectl_command(kube_config, f"kubectl delete pod {pod_name} -n {ns} --wait=false")

# Phase 05 (test_05_check.py): Poll up to 60s (sleep 15s) waiting for 3 Ready Pods:
for attempt in range(60 // 15):
    if available == 3 and ready == 3 and len(pods) == 3 and ready_pods == 3:
        return  # ✅ Self-healing verified!
    time.sleep(15)  # 💥 Exceeds API Gateway's 29-second synchronous AJAX timeout!
```

**2. The WS + Durable Function Solution (`durable_invoker.py` & `game-command-handler/app.py`):**
```python
# Step A: Non-blocking async hand-off (<100ms) from game-ws-handler
lambda_client.invoke(FunctionName=function_name, InvocationType="Event", Payload=...)

# Step B: @durable_execution chains Challenge -> Check & streams live WS status + ETA
def _execute_game_phase(email, game, task_id, endpoint, conn_id, state, manifest):
    _push_game_update(endpoint, conn_id, "talk", _running_payload(state, manifest))
    return task_service.execute_phase(email, game, task_id)
```

---

## MISSION 03 // End-to-End Serverless Python Pipeline

```
[1. HK Zero WebGL] ──(ws.send "talk")──▶ [2. API Gateway WebSocket]
                                                    │
[4. @durable_execution] ◀──(Async Invoke)── [3. game-ws-handler (Python)]
   (State Machine + Jinja2)                  (DynamoDB Cooldown & Mutex)
         │
         ▼
[5. TestRunner (pytest subprocess)] ──▶ Queries Student K8s Cluster
         │                              Uploads /tmp/report.html to S3 on Fail
         ▼
[6. boto3 apigatewaymanagementapi] ──(post_to_connection)──▶ [HK Zero Resumes!]
```

---

## STAGE 1 // WebSocket Ingestion & DynamoDB Guardrails

**Problem:** In an action game, players kill monsters rapidly. How do we prevent WebSocket spam from DoS-ing the test runner?

```python
# k8s-grader-api/game-ws-handler/app.py (Lines 153–206)
if not request_throttle_repo.claim_request(
    throttle_scope, email=email, channel="game_ws",
    action=action, cooldown_seconds=cooldown_seconds,
):
    _push_inline_game_status(event, action, {"status": "ERROR", ...})
    return _response(200, payload)

if not execution_guard_repo.acquire(
    execution_guard_key, email=email, channel="game_ws",
    action=action, ttl_seconds=guard_ttl_seconds,
):
    _push_inline_game_status(event, action, {"status": "ERROR", ...})
    return _response(200, payload)

request_id = _queue_game_command({"action": action, "connection_id": connection_id, ...})
execution_guard_repo.attach_request_id(execution_guard_key, request_id)
```

---

## What is AWS Lambda Durable Functions & Features We Use

- **Pure Python Stateful Workflows:** Write long-running workflows using `aws_durable_execution_sdk_python` directly inside Lambda—no Step Functions ASL JSON/YAML needed.
- **Checkpoint & Replay Engine:** Each `context.step()` checkpoints its output. On retry or resume, completed steps replay from history without re-running side effects.
- **4 Key Features Used in `k8s-grader-api`:**
  1. **`DurableConfig` + `:live` Alias (`template.yaml`):** `ExecutionTimeout: 3600` (1 hr) & `RetentionPeriodInDays: 14`.
  2. **`@durable_execution` & `DurableContext`:** Manages durable state across async invocations.
  3. **`@durable_step` Checkpointing:** Wraps `execute_game_command_step` as an atomic, replay-safe step.
  4. **Guaranteed Mutex Release (`try / finally`):** Always releases `execution_guard_key` in DynamoDB.

```yaml
# k8s-grader-api/template.yaml
GameCommandFunction:
  Type: AWS::Serverless::Function
  Properties:
    AutoPublishAlias: live
    DurableConfig:
      ExecutionTimeout: 3600      # 1-hour durable workflow horizon
      RetentionPeriodInDays: 14   # 14-day checkpoint & audit history
    Policies:
      - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicDurableExecutionRolePolicy
```

---

## STAGE 2 // Durable Execution & 6-Phase State Machine

```python
# k8s-grader-api/game-command-handler/app.py
from aws_durable_execution_sdk_python import DurableContext, durable_execution, durable_step

@durable_step
def execute_game_command_step(step_context, action, email, game, npc, endpoint, conn_id):
    return execute_game_command(action, email, game, npc, endpoint, conn_id)

@durable_execution
def lambda_handler(event: Dict[str, Any], context: DurableContext) -> Dict[str, Any]:
    try:
        payload = context.step(
            execute_game_command_step(action, email, game, npc, endpoint, conn_id)
        )
    finally:
        if execution_guard_key:
            execution_guard_repo.release(execution_guard_key)  # Always unlock student session!
    _push_game_update(endpoint, conn_id, action, payload)
```

---

## STAGE 3 // Anti-Cheating with Dynamic `Jinja2` Templating

**Problem:** How do we stop students from sharing static YAML solutions?

```python
# k8s-game-rule/tests/conftest.py
from jinja2 import Environment
from names_generator import generate_name

func_dict = {
    "student_id": lambda: "123456789",
    "random_name": lambda seed=0: generate_name(style="underscore", seed=seed).replace("_", ""),
    "random_number": lambda a, b: str(random.randint(a, b)),
    "base64_encode": lambda v: base64.b64encode(v.encode()).decode(),
}

def render(template: str) -> str:
    env = Environment()
    jinja_template = env.from_string(template)
    jinja_template.globals.update(func_dict)
    return jinja_template.render()
```

- Renders unique per-student pod names, ports, and secrets stored in DynamoDB `session_data`.
- Injected into **both** the HK Zero mission prompt and the `pytest` test assertions!

---

## STAGE 4 // Repurposing `pytest` as a Serverless Grader

**Why `pytest`?** Fixtures, expressive `assert` introspection, `-x` fail-fast, and `--self-contained-html` reports out of the box!

```python
# k8s-grader-api/common-layer/common/pytest.py
def run_tests(test_phase: GamePhrase, game: str, task: str, timeout: int = 30) -> TestResult:
    get_tests(game)  # Download & cache test suite in /tmp/{game}
    try:
        completed = subprocess.run(
            [
                sys.executable, "-m", "pytest",
                f"--rootdir={get_root_path(game)}",
                "--import-mode=importlib",
                "--html=/tmp/report.html",
                "--self-contained-html",
                "-x",  # Fail-fast for instant game feedback
                f"{get_test_base_path(game)}/{game}/{task}/test_{MAPPING[test_phase]}.py",
            ],
            env=build_pytest_env(), timeout=timeout, check=False,
        )
        return TestResult(completed.returncode)
    except subprocess.TimeoutExpired:
        return TestResult.TIME_OUT
```

---

## STAGE 5 // WebSocket Callback via `apigatewaymanagementapi`

**Closing the Loop:** Pushing the Python grading verdict straight back into the paused WebGL browser tab.

```python
# k8s-grader-api/game-command-handler/app.py
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return int(obj) if obj % 1 == 0 else float(obj)
        return super().default(obj)

def _send_ws_message(endpoint: str, connection_id: str, payload: Dict[str, Any]) -> None:
    client = boto3.client("apigatewaymanagementapi", endpoint_url=endpoint)
    message = json.dumps(payload, cls=DecimalEncoder).encode("utf-8")
    try:
        client.post_to_connection(ConnectionId=connection_id, Data=message)
    except client.exceptions.GoneException:
        logger.info("Game websocket connection %s is gone", connection_id)
```

---

<!-- _backgroundImage: "linear-gradient(rgba(8,15,23,0.82), rgba(13,23,32,0.92)), url('../hkzero/assets/illustrations/victory-v1.jpg')" -->

## MISSION COMPLETE // Key Takeaways & Open Source

1. **`pytest` Beyond Unit Tests:** Combine `pytest` + `Jinja2` + `--self-contained-html` to build a zero-boilerplate cloud infrastructure grader.
2. **Async WebSocket Pattern:** Fast DynamoDB mutex guards on ingest + `@durable_execution` + `post_to_connection` callbacks give games real-time cloud telemetry.
3. **One Backend, Many Worlds:** Powers **Hong Kong Zero** (`hkzero`), **DOOM** (`doom.ts`), **2D Isekai RPG** (`k8s-isekai`), and **Isolated Practical Exams** (`ENV=exam`).

- **GitHub:** `github.com/wongcyrus/k8s-game-platform`
- **Original Game:** `hongkongzero.com` (Special thanks to Arthur!)
