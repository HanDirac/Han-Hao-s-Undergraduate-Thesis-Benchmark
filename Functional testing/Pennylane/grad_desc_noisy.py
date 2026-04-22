import pennylane as qml
from pennylane import numpy as np


# -----------------------------
# 0. Logging utility
# -----------------------------
log_path = "grad_desc_log_noisy_pennylane.txt"
io = open(log_path, "w", encoding="utf-8")   # 覆盖写；若想追加可改为 "a"

def logprintln(io_obj, *args):
    msg = " ".join(str(x) for x in args)
    print(msg)             # stdout
    print(msg, file=io_obj)
    io_obj.flush()         # 立刻写入磁盘


try:
    # -----------------------------
    # 1. Problem setup
    # -----------------------------
    L = 3                  # number of qubits
    depth = 2              # circuit depth
    noise_p = 0.1          # depolarizing strength
    noise_gamma = 0.3      # amplitude damping strength
    noise_gamma_phase = 0.5 # phase damping strength

    eta = 0.01
    epochs = 10000

    hz = 1.0
    J = 1.0

    # 使用 mixed-state 设备，等效于 Julia 中的 DensityMatrix(L)
    dev = qml.device("default.mixed", wires=L)

    # -----------------------------
    # 2. Build Heisenberg Hamiltonian
    # -----------------------------
    # H = sum_i hz * Z_i + sum_i J * (X_iX_{i+1} + Y_iY_{i+1} + Z_iZ_{i+1})
    def heisenberg_1d(L, hz=1.0, J=1.0):
        coeffs = []
        ops = []

        # Local Z fields
        for i in range(L):
            coeffs.append(hz)
            ops.append(qml.PauliZ(i))

        # Nearest-neighbor interactions
        for i in range(L - 1):
            coeffs.append(J)
            ops.append(qml.PauliX(i) @ qml.PauliX(i + 1))

            coeffs.append(J)
            ops.append(qml.PauliY(i) @ qml.PauliY(i + 1))

            coeffs.append(J)
            ops.append(qml.PauliZ(i) @ qml.PauliZ(i + 1))

        return qml.Hamiltonian(coeffs, ops)

    H = heisenberg_1d(L, hz=hz, J=J)

    # -----------------------------
    # 3. Variational parameters
    # -----------------------------
    # 对应 Julia:
    #
    # First layer:
    #   Rz(pi/7), Ry(pi/7), Rz(pi/7)
    #
    # For each depth layer:
    #   CNOT chain
    #   Rz(pi/7), Rx(pi/7), Rz(pi/7)
    #   DepolarizingChannel(p=noise_p)
    #
    # 参数展平成一维向量 theta，模仿 active_parameters(circuit)

    first_layer = np.array(
        [[np.pi / 7, np.pi / 7, np.pi / 7] for _ in range(L)],
        requires_grad=True
    )

    later_layers = np.array(
        [[[np.pi / 7, np.pi / 7, np.pi / 7] for _ in range(L)] for _ in range(depth)],
        requires_grad=True
    )

    theta0 = np.concatenate([first_layer.ravel(), later_layers.ravel()])
    theta = np.array(theta0, requires_grad=True)

    num_first = L * 3
    num_later = depth * L * 3
    num_params = num_first + num_later

    def unpack_theta(theta):
        """把一维参数向量还原成线路结构。"""
        if len(theta) != num_params:
            raise ValueError(
                f"Parameter length mismatch: expected {num_params}, got {len(theta)}"
            )

        first = theta[:num_first].reshape((L, 3))
        later = theta[num_first:].reshape((depth, L, 3))
        return first, later

    # -----------------------------
    # 4. Define circuit and loss
    # -----------------------------
    @qml.qnode(dev, interface="autograd", diff_method="backprop")
    def circuit(theta):
        first, later = unpack_theta(theta)

        # 初态默认就是 |000...0><000...0|，不需要额外准备

        # First layer: Rz, Ry, Rz
        for i in range(L):
            qml.RZ(first[i, 0], wires=i)
            qml.RY(first[i, 1], wires=i)
            qml.RZ(first[i, 2], wires=i)

        # Repeated entangling + rotations + noise
        for l in range(depth):
            # entangling chain
            for i in range(L - 1):
                qml.CNOT(wires=[i, i + 1])

            # local rotations: Rz, Rx, Rz
            for i in range(L):
                qml.RZ(later[l, i, 0], wires=i)
                qml.RX(later[l, i, 1], wires=i)
                qml.RZ(later[l, i, 2], wires=i)

            # add depolarizing noise
            for i in range(L):
                qml.DepolarizingChannel(noise_p, wires=i)
                qml.AmplitudeDamping(noise_gamma, wires=i)
                qml.PhaseDamping(noise_gamma_phase, wires=i)

        return qml.expval(H)

    def loss_fn(theta):
        return circuit(theta)

    grad_fn = qml.grad(loss_fn)

    # -----------------------------
    # 5. Gradient-descent loop
    # -----------------------------
    logprintln(io, f"Start training: L={L}, depth={depth}, eta={eta}, epochs={epochs}")
    logprintln(io, f"noise_p = {noise_p}")
    logprintln(io, f"Number of parameters: {num_params}")
    logprintln(io, f"Log file: {log_path}")

    for epoch in range(1, epochs + 1):
        g_theta = grad_fn(theta)
        logprintln(io, f"Epoch {epoch}: gradient = {g_theta}")

        theta = theta - eta * g_theta

        current_loss = loss_fn(theta)
        logprintln(io, f"Epoch {epoch}: loss = {current_loss}")
        logprintln(io, "")

    logprintln(io, "Finished training.")

finally:
    io.close()