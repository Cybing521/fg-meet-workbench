function result = run_isomorphic_solid_cfff(nx, ny, nz, loadCases)
%RUN_ISOMORPHIC_SOLID_CFFF Structured H20 solid matching the COMSOL 3D model.
%   RESULT = RUN_ISOMORPHIC_SOLID_CFFF(NX,NY,NZ,LOADCASES) solves a
%   300 mm x 300 mm x 6 mm CFFF solid using 20-node serendipity brick
%   elements, quadratic displacement interpolation, full 3x3x3 integration,
%   E=1.206e11 Pa and nu=0.3398. NZ must be a multiple of ten so each
%   physical layer has the same number of elements. LOADCASES is a struct
%   array with fields name, bottom_stress_Pa and top_stress_Pa. The stresses
%   enter exactly as COMSOL ExternalStress contributions in the two outer
%   layers.

arguments
    nx (1,1) double {mustBeInteger,mustBePositive}
    ny (1,1) double {mustBeInteger,mustBePositive}
    nz (1,1) double {mustBeInteger,mustBePositive}
    loadCases (1,:) struct
end
if mod(nz, 10) ~= 0
    error('run_isomorphic_solid_cfff:LayerMesh', ...
        'nz must be a multiple of 10; received %d.', nz);
end
required = {'name','bottom_stress_Pa','top_stress_Pa'};
for i = 1:numel(loadCases)
    for j = 1:numel(required)
        if ~isfield(loadCases(i), required{j})
            error('run_isomorphic_solid_cfff:LoadCase', ...
                'loadCases(%d) is missing %s.', i, required{j});
        end
    end
end
self_test_h20();

L = 0.300;
W = 0.300;
H = 0.006;
E = 1.206e11;
nu = 0.3398;
dx = L / nx;
dy = W / ny;
dz = H / nz;
elementsPerPhysicalLayer = nz / 10;

[corner, xedge, yedge, zedge, nodeCount] = create_node_ids(nx, ny, nz);
ndof = 3 * nodeCount;
[Ke, feUnit] = h20_element_matrices(dx, dy, dz, E, nu);
K = sparse(ndof, ndof);
F = zeros(ndof, numel(loadCases));
elementCount = nx * ny * nz;

for k = 1:nz
    conn = layer_connectivity(k, nx, ny, corner, xedge, yedge, zedge);
    layerElements = size(conn, 1);
    edofs = element_dofs(conn);
    ntrip = layerElements * numel(Ke);
    I = zeros(ntrip, 1, 'uint32');
    J = zeros(ntrip, 1, 'uint32');
    V = repmat(Ke(:), layerElements, 1);
    cursor = 0;
    for e = 1:layerElements
        dofs = edofs(e, :);
        [ii, jj] = ndgrid(dofs, dofs);
        block = cursor + (1:numel(Ke));
        I(block) = uint32(ii(:));
        J(block) = uint32(jj(:));
        cursor = cursor + numel(Ke);
    end
    K = K + sparse(double(I), double(J), V, ndof, ndof);

    physicalLayer = ceil(k / elementsPerPhysicalLayer);
    if physicalLayer == 1 || physicalLayer == 10
        for c = 1:numel(loadCases)
            if physicalLayer == 1
                stress = loadCases(c).bottom_stress_Pa;
            else
                stress = loadCases(c).top_stress_Pa;
            end
            localLoads = repmat((feUnit * stress).', layerElements, 1);
            F(:, c) = F(:, c) + accumarray(edofs(:), localLoads(:), [ndof, 1]);
        end
    end
end
K = (K + K.') / 2;

fixedNodes = unique([reshape(corner(1, :, :), [], 1); ...
    reshape(yedge(1, :, :), [], 1); reshape(zedge(1, :, :), [], 1)]);
fixedDofs = reshape([3 * fixedNodes - 2, 3 * fixedNodes - 1, 3 * fixedNodes].', [], 1);
freeMask = true(ndof, 1);
freeMask(fixedDofs) = false;
free = find(freeMask);
U = zeros(ndof, numel(loadCases));
Kfree = K(free, free);
Ffree = F(free, :);
U(free, :) = Kfree \ Ffree;
relativeResidual = zeros(numel(loadCases), 1);
for c = 1:numel(loadCases)
    relativeResidual(c) = norm(Kfree * U(free, c) - Ffree(:, c)) / ...
        max(norm(Ffree(:, c)), eps);
end

wCenter = zeros(numel(loadCases), 1);
wFreeMid = zeros(numel(loadCases), 1);
for c = 1:numel(loadCases)
    wCenter(c) = interpolate_w(U(:, c), L/2, W/2, 0, ...
        nx, ny, nz, L, W, H, corner, xedge, yedge, zedge);
    wFreeMid(c) = interpolate_w(U(:, c), L, W/2, 0, ...
        nx, ny, nz, L, W, H, corner, xedge, yedge, zedge);
end

result = table(string({loadCases.name}).', ...
    [loadCases.bottom_stress_Pa].', [loadCases.top_stress_Pa].', ...
    repmat(nx, numel(loadCases), 1), repmat(ny, numel(loadCases), 1), ...
    repmat(nz, numel(loadCases), 1), ...
    repmat(elementsPerPhysicalLayer, numel(loadCases), 1), ...
    repmat(elementCount, numel(loadCases), 1), ...
    repmat(nodeCount, numel(loadCases), 1), repmat(ndof, numel(loadCases), 1), ...
    1000 * wCenter, 1000 * wFreeMid, relativeResidual, ...
    repmat("completed", numel(loadCases), 1), ...
    'VariableNames', {'load_case','bottom_stress_Pa','top_stress_Pa', ...
    'nx','ny','nz_total','thickness_elements_per_physical_layer', ...
    'element_count','node_count','dof_count','w_center_mm','w_free_mid_mm', ...
    'relative_equilibrium_residual','status'});
end

function [corner, xedge, yedge, zedge, nodeCount] = create_node_ids(nx, ny, nz)
next = 0;
corner = reshape(next + (1:(nx+1)*(ny+1)*(nz+1)), nx+1, ny+1, nz+1);
next = max(corner(:));
xedge = reshape(next + (1:nx*(ny+1)*(nz+1)), nx, ny+1, nz+1);
next = max(xedge(:));
yedge = reshape(next + (1:(nx+1)*ny*(nz+1)), nx+1, ny, nz+1);
next = max(yedge(:));
zedge = reshape(next + (1:(nx+1)*(ny+1)*nz), nx+1, ny+1, nz);
nodeCount = max(zedge(:));
end

function conn = layer_connectivity(k, nx, ny, corner, xedge, yedge, zedge)
conn = zeros(nx * ny, 20);
e = 0;
for j = 1:ny
    for i = 1:nx
        e = e + 1;
        conn(e, :) = [ ...
            corner(i,j,k), corner(i+1,j,k), corner(i+1,j+1,k), corner(i,j+1,k), ...
            corner(i,j,k+1), corner(i+1,j,k+1), corner(i+1,j+1,k+1), corner(i,j+1,k+1), ...
            xedge(i,j,k), yedge(i+1,j,k), xedge(i,j+1,k), yedge(i,j,k), ...
            xedge(i,j,k+1), yedge(i+1,j,k+1), xedge(i,j+1,k+1), yedge(i,j,k+1), ...
            zedge(i,j,k), zedge(i+1,j,k), zedge(i+1,j+1,k), zedge(i,j+1,k)];
    end
end
end

function edofs = element_dofs(conn)
edofs = zeros(size(conn,1), 3 * size(conn,2));
edofs(:, 1:3:end) = 3 * conn - 2;
edofs(:, 2:3:end) = 3 * conn - 1;
edofs(:, 3:3:end) = 3 * conn;
end

function [Ke, feUnit] = h20_element_matrices(dx, dy, dz, E, nu)
lambda = E * nu / ((1 + nu) * (1 - 2 * nu));
mu = E / (2 * (1 + nu));
D = [lambda+2*mu, lambda, lambda, 0, 0, 0; ...
     lambda, lambda+2*mu, lambda, 0, 0, 0; ...
     lambda, lambda, lambda+2*mu, 0, 0, 0; ...
     0, 0, 0, mu, 0, 0; 0, 0, 0, 0, mu, 0; 0, 0, 0, 0, 0, mu];
gp = [-sqrt(3/5), 0, sqrt(3/5)];
gw = [5/9, 8/9, 5/9];
detJ = dx * dy * dz / 8;
invScale = [2/dx; 2/dy; 2/dz];
Ke = zeros(60, 60);
feUnit = zeros(60, 1);
unitStress = [1; 1; 0; 0; 0; 0];
for a = 1:3
    for b = 1:3
        for c = 1:3
            [~, dNnatural] = h20_shape(gp(a), gp(b), gp(c));
            dN = dNnatural .* invScale;
            B = zeros(6, 60);
            B(1, 1:3:end) = dN(1, :);
            B(2, 2:3:end) = dN(2, :);
            B(3, 3:3:end) = dN(3, :);
            B(4, 1:3:end) = dN(2, :);
            B(4, 2:3:end) = dN(1, :);
            B(5, 2:3:end) = dN(3, :);
            B(5, 3:3:end) = dN(2, :);
            B(6, 1:3:end) = dN(3, :);
            B(6, 3:3:end) = dN(1, :);
            weight = gw(a) * gw(b) * gw(c) * detJ;
            Ke = Ke + B.' * D * B * weight;
            feUnit = feUnit - B.' * unitStress * weight;
        end
    end
end
end

function value = interpolate_w(U, x, y, z, nx, ny, nz, L, W, H, corner, xedge, yedge, zedge)
dx = L / nx; dy = W / ny; dz = H / nz;
i = min(max(ceil(x / dx), 1), nx);
j = min(max(ceil(y / dy), 1), ny);
k = min(max(ceil((z + H/2) / dz), 1), nz);
xi = 2 * (x - (i-1)*dx) / dx - 1;
eta = 2 * (y - (j-1)*dy) / dy - 1;
zeta = 2 * (z + H/2 - (k-1)*dz) / dz - 1;
conn = layer_connectivity(k, nx, ny, corner, xedge, yedge, zedge);
local = conn((j-1)*nx + i, :);
[N, ~] = h20_shape(xi, eta, zeta);
value = N * U(3 * local);
end

function [N, dN] = h20_shape(xi, eta, zeta)
cornerSigns = [-1,-1,-1; 1,-1,-1; 1,1,-1; -1,1,-1; ...
               -1,-1,1; 1,-1,1; 1,1,1; -1,1,1];
N = zeros(1, 20);
dN = zeros(3, 20);
for n = 1:8
    sx = cornerSigns(n,1); sy = cornerSigns(n,2); sz = cornerSigns(n,3);
    A = 1 + sx*xi; B = 1 + sy*eta; C = 1 + sz*zeta;
    Q = sx*xi + sy*eta + sz*zeta - 2;
    N(n) = A * B * C * Q / 8;
    dN(1,n) = sx * B * C * (Q + A) / 8;
    dN(2,n) = sy * A * C * (Q + B) / 8;
    dN(3,n) = sz * A * B * (Q + C) / 8;
end
edgeDefs = [ ...
    1, 0,-1,-1; 2, 1, 0,-1; 1, 0, 1,-1; 2,-1, 0,-1; ...
    1, 0,-1, 1; 2, 1, 0, 1; 1, 0, 1, 1; 2,-1, 0, 1; ...
    3,-1,-1, 0; 3, 1,-1, 0; 3, 1, 1, 0; 3,-1, 1, 0];
for q = 1:12
    n = 8 + q;
    axis = edgeDefs(q,1); sx = edgeDefs(q,2); sy = edgeDefs(q,3); sz = edgeDefs(q,4);
    if axis == 1
        B = 1 + sy*eta; C = 1 + sz*zeta;
        N(n) = (1-xi^2) * B * C / 4;
        dN(:,n) = [-xi*B*C/2; (1-xi^2)*sy*C/4; (1-xi^2)*B*sz/4];
    elseif axis == 2
        A = 1 + sx*xi; C = 1 + sz*zeta;
        N(n) = (1-eta^2) * A * C / 4;
        dN(:,n) = [(1-eta^2)*sx*C/4; -eta*A*C/2; (1-eta^2)*A*sz/4];
    else
        A = 1 + sx*xi; B = 1 + sy*eta;
        N(n) = (1-zeta^2) * A * B / 4;
        dN(:,n) = [(1-zeta^2)*sx*B/4; (1-zeta^2)*A*sy/4; -zeta*A*B/2];
    end
end
end

function self_test_h20()
persistent passed
if ~isempty(passed)
    return;
end
samples = [-0.37,0.21,0.59; 0,0,0; 0.8,-0.6,0.1];
for i = 1:size(samples,1)
    [N,dN] = h20_shape(samples(i,1), samples(i,2), samples(i,3));
    if abs(sum(N)-1) > 1e-12 || max(abs(sum(dN,2))) > 1e-12
        error('run_isomorphic_solid_cfff:ShapeFunction', ...
            'H20 partition of unity test failed.');
    end
end
naturalNodes = [-1,-1,-1; 1,-1,-1; 1,1,-1; -1,1,-1; ...
    -1,-1,1; 1,-1,1; 1,1,1; -1,1,1; ...
    0,-1,-1; 1,0,-1; 0,1,-1; -1,0,-1; ...
    0,-1,1; 1,0,1; 0,1,1; -1,0,1; ...
    -1,-1,0; 1,-1,0; 1,1,0; -1,1,0];
for i = 1:20
    N = h20_shape(naturalNodes(i,1), naturalNodes(i,2), naturalNodes(i,3));
    expected = zeros(1,20); expected(i) = 1;
    if max(abs(N-expected)) > 1e-12
        error('run_isomorphic_solid_cfff:ShapeFunction', ...
            'H20 Kronecker test failed at node %d.', i);
    end
end
passed = true;
end
