const show = (id, data) => {
  document.getElementById(id).textContent = JSON.stringify(data, null, 2);
};

const request = async (url, options = {}) => {
  const response = await fetch(url, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  const data = await response.json();
  if (!response.ok) {
    throw data;
  }
  return data;
};

const services = [
  ["Auth", "/health/auth"],
  ["Users", "/health/users"],
  ["Products", "/health/products"],
  ["Orders", "/health/orders"],
  ["Chat", "/health/chat"],
];

const loadServiceStatus = async () => {
  const checks = await Promise.all(
    services.map(async ([name, url]) => {
      try {
        const response = await fetch(url);
        return { name, ok: response.ok };
      } catch {
        return { name, ok: false };
      }
    })
  );

  document.getElementById("service-status").innerHTML = checks
    .map(
      (service) => `
        <div class="status-card ${service.ok ? "ok" : "bad"}">
          <strong>${service.name}</strong>
          <span>${service.ok ? "healthy" : "down"}</span>
        </div>
      `
    )
    .join("");
};

const loadProducts = async () => {
  const products = await request("/api/products/");
  document.getElementById("products").innerHTML = products
    .map(
      (product) => `
        <div class="product">
          <strong>#${product.id} ${product.name}</strong>
          <div>${product.description}</div>
          <div class="meta"><span>$${product.price}</span><span>stock ${product.stock}</span></div>
        </div>
      `
    )
    .join("");
};

const refresh = async () => {
  await loadServiceStatus();
  await loadProducts();
  show("users-output", await request("/api/users/"));
  show("orders-output", await request("/api/orders/"));
  show("chat-output", await request("/api/chat/messages"));
};

document.getElementById("register").onclick = async () => {
  try {
    show("auth-output", await request("/api/auth/register", {
      method: "POST",
      body: JSON.stringify({
        username: document.getElementById("username").value,
        password: document.getElementById("password").value,
        role: document.getElementById("role").value,
      }),
    }));
  } catch (error) {
    show("auth-output", error);
  }
};

document.getElementById("login").onclick = async () => {
  try {
    show("auth-output", await request("/api/auth/login", {
      method: "POST",
      body: JSON.stringify({
        username: document.getElementById("username").value,
        password: document.getElementById("password").value,
      }),
    }));
  } catch (error) {
    show("auth-output", error);
  }
};

document.getElementById("create-user").onclick = async () => {
  try {
    show("users-output", await request("/api/users/", {
      method: "POST",
      body: JSON.stringify({
        username: document.getElementById("profile-username").value,
        email: document.getElementById("profile-email").value,
      }),
    }));
  } catch (error) {
    show("users-output", error);
  }
};

document.getElementById("create-order").onclick = async () => {
  try {
    show("orders-output", await request("/api/orders/", {
      method: "POST",
      body: JSON.stringify({
        user_id: Number(document.getElementById("order-user").value),
        product_id: Number(document.getElementById("order-product").value),
        quantity: Number(document.getElementById("order-quantity").value),
      }),
    }));
  } catch (error) {
    show("orders-output", error);
  }
};

document.getElementById("send-message").onclick = async () => {
  try {
    show("chat-output", await request("/api/chat/messages", {
      method: "POST",
      body: JSON.stringify({
        sender_id: Number(document.getElementById("chat-sender").value),
        receiver_id: Number(document.getElementById("chat-receiver").value),
        message: document.getElementById("chat-message").value,
      }),
    }));
  } catch (error) {
    show("chat-output", error);
  }
};

document.getElementById("refresh").onclick = refresh;
refresh().catch((error) => console.error(error));
