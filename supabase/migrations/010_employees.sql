-- ============================================
-- OMNIGO Migration 010: Employees & HR
-- ============================================

-- Employees (extends users with HR info)
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES tenant_branches(id) ON DELETE SET NULL,
    employee_code VARCHAR(50),
    department VARCHAR(100),
    position VARCHAR(100),
    salary DECIMAL(15, 2),
    hire_date DATE,
    contract_end_date DATE,
    emergency_contact VARCHAR(255),
    emergency_phone VARCHAR(20),
    note TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_employees_user ON employees(user_id);
CREATE INDEX idx_employees_tenant ON employees(tenant_id);
CREATE INDEX idx_employees_branch ON employees(branch_id);
CREATE INDEX idx_employees_code ON employees(tenant_id, employee_code);

-- Attendance (chấm công)
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    type attendance_type NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT now(),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_name VARCHAR(255),
    is_verified BOOLEAN DEFAULT false,  -- GPS within branch range
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_attendance_employee ON attendance(employee_id);
CREATE INDEX idx_attendance_tenant ON attendance(tenant_id);
CREATE INDEX idx_attendance_date ON attendance(tenant_id, timestamp);

-- Tasks (giao việc)
CREATE TABLE employee_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    assigned_to UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status task_status DEFAULT 'todo',
    priority INT DEFAULT 0,
    due_date TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_tasks_tenant ON employee_tasks(tenant_id);
CREATE INDEX idx_tasks_assigned ON employee_tasks(assigned_to);
CREATE INDEX idx_tasks_status ON employee_tasks(tenant_id, status);
CREATE INDEX idx_tasks_due ON employee_tasks(due_date) WHERE status != 'done';
