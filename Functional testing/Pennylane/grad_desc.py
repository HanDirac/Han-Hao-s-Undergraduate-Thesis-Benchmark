import pennylane as qml
from pennylane import numpy as np


# -----------------------------
# 0. Logging utility
# -----------------------------
log_path = "grad_desc_log_pennylane.txt"
io = open(log_path, "w", encoding="utf-8")  # 若想追加可改成 "a"


def logprintln(io_obj, *args):
    msg = " ".join(str(x) for x in args)
    print(msg)            # stdout
    print(msg, file=io_obj)
    io_obj.flush()        # 立刻写入磁盘


try:
    # -----------------------------
    # 1. Problem setup
    # -----------------------------
    L = 3                 # number of qubits
    depth = 2             # circuit depth
    eta = 0.01
    epochs = 10000

    hz = 1.0
    J = 1.0

    # 默认初态就是 |000...0>，所以不需要额外准备 ψ0
    dev = qml.device("default.qubit", wires=L)

    # -----------------------------
    # 2. Build Heisenberg Hamiltonian
    # -----------------------------
    def heisenberg_1d(L, hz=1.0, J=1.0):
        coeffs = []
        ops = []

        # Local Z fields
        for i in range(L):
            coeffs.append(hz)
            ops.append(qml.PauliZ(i))

        # Nearest-neighbor interactions: XX + YY + ZZ
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
    # 与 Julia 版本尽量对应：
    #
    # 第一层每个量子位：
    #   Rz(pi/7), Ry(pi/5), Rz(pi/3)
    #
    # 后续每个 depth 层：
    #   先一串 CNOT
    #   再每个量子位：
    #   Rz(pi/7), Rx(pi/5), Rz(pi/3)
    #
    # 我们把参数组织成：
    #   first_layer.shape = (L, 3)
    #   later_layers.shape = (depth, L, 3)
    #
    # 其中 first_layer[i] = [rz1, ry, rz2]
    # later_layers[l, i] = [rz1, rx, rz2]

    first_layer = np.array(
        [[np.pi / 7, np.pi / 5, np.pi / 3] for _ in range(L)],
        requires_grad=True
    )

    later_layers = np.array(
        [[[np.pi / 7, np.pi / 5, np.pi / 3] for _ in range(L)] for _ in range(depth)],
        requires_grad=True
    )

    # 为了更接近 Julia 中 active_parameters(circuit) 返回的一维参数向量，
    # 这里将所有参数展平为一个一维数组 θ。
    theta0 = np.concatenate([first_layer.ravel(), later_layers.ravel()])
    theta = np.array(theta0, requires_grad=True)

    num_first = L * 3
    num_later = depth * L * 3
    num_params = num_first + num_later

    # -----------------------------
    # 4. Define circuit and loss
    # -----------------------------
    def unpack_theta(theta):
        """把一维参数向量还原成线路所需的结构。"""
        if len(theta) != num_params:
            raise ValueError(
                f"Parameter length mismatch: expected {num_params}, got {len(theta)}"
            )

        first = theta[:num_first].reshape((L, 3))
        later = theta[num_first:].reshape((depth, L, 3))
        return first, later

    @qml.qnode(dev, interface="autograd", diff_method="backprop")
    def circuit(theta):
        first, later = unpack_theta(theta)

        # First layer: Rz, Ry, Rz
        for i in range(L):
            qml.RZ(first[i, 0], wires=i)
            qml.RY(first[i, 1], wires=i)
            qml.RZ(first[i, 2], wires=i)

        # Repeated entangling + rotations
        for l in range(depth):
            # entangling chain
            for i in range(L - 1):
                qml.CNOT(wires=[i, i + 1])

            # local rotations: Rz, Rx, Rz
            for i in range(L):
                qml.RZ(later[l, i, 0], wires=i)
                qml.RX(later[l, i, 1], wires=i)
                qml.RZ(later[l, i, 2], wires=i)

        return qml.expval(H)

    def loss_fn(theta):
        return circuit(theta)

    grad_fn = qml.grad(loss_fn)

    # -----------------------------
    # 5. Gradient-descent loop
    # -----------------------------
    logprintln(io, f"Start training: L={L}, depth={depth}, eta={eta}, epochs={epochs}")
    logprintln(io, f"Number of parameters: {num_params}")
    logprintln(io, f"Log file: {log_path}")

    for epoch in range(1, epochs + 1):
        g_theta = grad_fn(theta)
        theta = theta - eta * g_theta

        current_loss = loss_fn(theta)
        logprintln(io, f"Epoch {epoch}: loss = {current_loss}")

    logprintln(io, "Finished training.")

    # 若你想在训练结束后查看最终参数，可取消下面注释
    # logprintln(io, "Final theta =", theta)

finally:
    io.close()