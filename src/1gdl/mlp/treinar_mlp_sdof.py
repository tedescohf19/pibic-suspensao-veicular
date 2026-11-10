"""
TREINAMENTO DE REDE NEURAL (MLP) - SISTEMA SDOF (SUSPENSAO PASSIVA 1-GDL)
Lê os arquivos:
  - banco_treino_1000.csv
  - banco_validacao_200.csv
  - banco_teste_cego_28_rao.csv
Treina o modelo em PyTorch, avalia métricas (MAPE e R2) e plota gráficos de paridade e convergência.
"""

import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import r2_score
import matplotlib.pyplot as plt

# 1. Reprodutibilidade
np.random.seed(42)
torch.manual_seed(42)

# 2. Carregamento dos Bancos de Dados
df_train = pd.read_csv('banco_treino_1000.csv')
df_val   = pd.read_csv('banco_validacao_200.csv')
df_test  = pd.read_csv('banco_teste_cego_28_rao.csv')

# 3. Engenharia de Atributos Física (Sem vazamento de dados)
def build_features(df):
    r = df['r'].values
    dst = df['dst'].values
    wn = df['wn'].values
    w = df['w'].values
    x0 = df['x0'].values
    v0 = df['v0'].values
    tf = df['tf'].values
    zeta = 0.02  # Taxa de amortecimento fixa de 2%
    
    log_r = np.log10(r)
    log_dst = np.log10(dst)
    log_wn = np.log10(wn)
    log_w = np.log10(w)
    
    # Termo físico adimensional de impedância
    log_imp = 0.5 * np.log10((1.0 - r**2)**2 + (2.0 * zeta * r)**2)
    # Fator de decaimento acumulado na janela temporal tf
    decay_factor = 1.0 - np.exp(-zeta * wn * tf)
    
    X = np.column_stack([
        r, log_r, log_imp,
        dst, log_dst,
        wn, log_wn, log_w,
        x0, v0, np.abs(x0), np.abs(v0),
        decay_factor, np.log10(tf * wn)
    ])
    return X

target_cols = ['X_teor', 'Xmax_total', 'x_rms', 'v_rms', 'a_rms']

X_tr_raw = build_features(df_train)
X_va_raw = build_features(df_val)
X_te_raw = build_features(df_test)

# Transformação log10 nos alvos estritamente positivos (cobre 4 ordens de grandeza)
Y_tr_log = np.log10(df_train[target_cols].values)
Y_va_log = np.log10(df_val[target_cols].values)
Y_te_log = np.log10(df_test[target_cols].values)

scaler_X = StandardScaler()
scaler_Y = StandardScaler()

X_tr = scaler_X.fit_transform(X_tr_raw)
X_va = scaler_X.transform(X_va_raw)
X_te = scaler_X.transform(X_te_raw)

Y_tr = scaler_Y.fit_transform(Y_tr_log)
Y_va = scaler_Y.transform(Y_va_log)
Y_te = scaler_Y.transform(Y_te_log)

# 4. Definição da Arquitetura MLP
class SuspensionMLP(nn.Module):
    def __init__(self, in_dim, out_dim):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(in_dim, 128),
            nn.SiLU(),
            nn.Linear(128, 128),
            nn.SiLU(),
            nn.Linear(128, 64),
            nn.SiLU(),
            nn.Linear(64, out_dim)
        )
        
    def forward(self, x):
        return self.net(x)

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = SuspensionMLP(X_tr.shape[1], len(target_cols)).to(device)

criterion = nn.MSELoss()
optimizer = torch.optim.AdamW(model.parameters(), lr=3e-3, weight_decay=1e-4)
scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.5, patience=20)

X_tr_t = torch.tensor(X_tr, dtype=torch.float32).to(device)
Y_tr_t = torch.tensor(Y_tr, dtype=torch.float32).to(device)
X_va_t = torch.tensor(X_va, dtype=torch.float32).to(device)
Y_va_t = torch.tensor(Y_va, dtype=torch.float32).to(device)
X_te_t = torch.tensor(X_te, dtype=torch.float32).to(device)

train_loader = DataLoader(TensorDataset(X_tr_t, Y_tr_t), batch_size=32, shuffle=True)

# 5. Loop de Treinamento com Early Saving do Melhor Modelo
epochs = 450
train_losses, val_losses = [], []
best_val_loss = float('inf')
best_state = None

for epoch in range(epochs):
    model.train()
    ep_loss = 0.0
    for bx, by in train_loader:
        optimizer.zero_grad()
        pred = model(bx)
        loss = criterion(pred, by)
        loss.backward()
        optimizer.step()
        ep_loss += loss.item() * len(bx)
        
    ep_loss /= len(X_tr_t)
    train_losses.append(ep_loss)
    
    model.eval()
    with torch.no_grad():
        val_pred = model(X_va_t)
        v_loss = criterion(val_pred, Y_va_t).item()
        val_losses.append(v_loss)
        if v_loss < best_val_loss:
            best_val_loss = v_loss
            best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}
            
    scheduler.step(v_loss)
    if (epoch + 1) % 50 == 0:
        print(f"Epoca [{epoch+1:03d}/{epochs}] | Train Loss: {ep_loss:.6f} | Val Loss: {v_loss:.6f}")

# Restaurar o melhor estado validado
model.load_state_dict({k: v.to(device) for k, v in best_state.items()})
model.eval()

# 6. Avaliação e Conversão para Escala Física Real
with torch.no_grad():
    pred_tr_real = 10 ** scaler_Y.inverse_transform(model(X_tr_t).cpu().numpy())
    pred_va_real = 10 ** scaler_Y.inverse_transform(model(X_va_t).cpu().numpy())
    pred_te_real = 10 ** scaler_Y.inverse_transform(model(X_te_t).cpu().numpy())

real_tr = df_train[target_cols].values
real_va = df_val[target_cols].values
real_te = df_test[target_cols].values

print("\n=== RESULTADOS GLOBAIS DE DESEMPENHO ===")
for i, col in enumerate(target_cols):
    mape_tr = np.mean(np.abs((real_tr[:, i] - pred_tr_real[:, i]) / real_tr[:, i])) * 100
    mape_va = np.mean(np.abs((real_va[:, i] - pred_va_real[:, i]) / real_va[:, i])) * 100
    mape_te = np.mean(np.abs((real_te[:, i] - pred_te_real[:, i]) / real_te[:, i])) * 100
    r2_te   = r2_score(real_te[:, i], pred_te_real[:, i])
    print(f"{col:12s} | Treino MAPE: {mape_tr:5.2f}% | Val MAPE: {mape_va:5.2f}% | Teste Cego (28 Rao) MAPE: {mape_te:5.2f}% (R2 = {r2_te:.4f})")

# Salvar tabela comparativa dos 28 casos do Rao
df_comp = pd.DataFrame({
    'id': df_test['id'],
    'r': df_test['r'].round(4),
    'X_teor_Real_mm': (real_te[:, 0]*1e3).round(3),
    'X_teor_MLP_mm': (pred_te_real[:, 0]*1e3).round(3),
    'Xmax_Real_mm': (real_te[:, 1]*1e3).round(3),
    'Xmax_MLP_mm': (pred_te_real[:, 1]*1e3).round(3),
    'x_rms_Real_mm': (real_te[:, 2]*1e3).round(3),
    'x_rms_MLP_mm': (pred_te_real[:, 2]*1e3).round(3),
    'a_rms_Real_ms2': real_te[:, 4].round(3),
    'a_rms_MLP_ms2': pred_te_real[:, 4].round(3)
})
df_comp.to_csv('predicoes_mlp_28_casos_rao.csv', index=False)

# 7. Gráficos de Convergência e Paridade
fig, axes = plt.subplots(2, 2, figsize=(13, 10))

axes[0, 0].plot(train_losses, 'b-', label='Treino (1000 casos)')
axes[0, 0].plot(val_losses, 'r--', label='Validacao (200 casos)')
axes[0, 0].set_yscale('log')
axes[0, 0].set_xlabel('Epoca')
axes[0, 0].set_ylabel('MSE Loss (log)')
axes[0, 0].set_title('Curva de Aprendizado (Sem Overfitting)')
axes[0, 0].grid(True, which='both', linestyle='--', alpha=0.5)
axes[0, 0].legend()

# Paridade Xmax_total
axes[0, 1].scatter(real_va[:, 1]*1e3, pred_va_real[:, 1]*1e3, c='darkorange', alpha=0.6, label='Validacao')
axes[0, 1].scatter(real_te[:, 1]*1e3, pred_te_real[:, 1]*1e3, c='crimson', marker='^', s=60, edgecolors='k', label='28 Casos Rao')
axes[0, 1].plot([0.1, 3500], [0.1, 3500], 'k--')
axes[0, 1].set_xscale('log'); axes[0, 1].set_yscale('log')
axes[0, 1].set_xlabel('Max|x| Real [mm]'); axes[0, 1].set_ylabel('Max|x| MLP [mm]')
axes[0, 1].set_title('Paridade: Deslocamento Maximo Total')
axes[0, 1].grid(True, which='both', linestyle='--', alpha=0.5); axes[0, 1].legend()

# Paridade x_rms
axes[1, 0].scatter(real_va[:, 2]*1e3, pred_va_real[:, 2]*1e3, c='royalblue', alpha=0.6, label='Validacao')
axes[1, 0].scatter(real_te[:, 2]*1e3, pred_te_real[:, 2]*1e3, c='crimson', marker='^', s=60, edgecolors='k', label='28 Casos Rao')
axes[1, 0].plot([0.08, 2500], [0.08, 2500], 'k--')
axes[1, 0].set_xscale('log'); axes[1, 0].set_yscale('log')
axes[1, 0].set_xlabel('x_rms Real [mm]'); axes[1, 0].set_ylabel('x_rms MLP [mm]')
axes[1, 0].set_title('Paridade: Deslocamento RMS')
axes[1, 0].grid(True, which='both', linestyle='--', alpha=0.5); axes[1, 0].legend()

# Paridade a_rms
axes[1, 1].scatter(real_va[:, 4], pred_va_real[:, 4], c='seagreen', alpha=0.6, label='Validacao')
axes[1, 1].scatter(real_te[:, 4], pred_te_real[:, 4], c='crimson', marker='^', s=60, edgecolors='k', label='28 Casos Rao')
axes[1, 1].plot([0.02, 2500], [0.02, 2500], 'k--')
axes[1, 1].set_xscale('log'); axes[1, 1].set_yscale('log')
axes[1, 1].set_xlabel('a_rms Real [m/s^2]'); axes[1, 1].set_ylabel('a_rms MLP [m/s^2]')
axes[1, 1].set_title('Paridade: Aceleracao RMS (Conforto)')
axes[1, 1].grid(True, which='both', linestyle='--', alpha=0.5); axes[1, 1].legend()

plt.tight_layout()
plt.savefig('resultados_treinamento_mlp.png', dpi=150)
plt.show()
