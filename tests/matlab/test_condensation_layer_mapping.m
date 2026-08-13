function tests = test_condensation_layer_mapping
%TEST_CONDENSATION_LAYER_MAPPING Missing element layers retain correct MEE slots.
    tests = functiontests(localfunctions);
end

function testMiddleLayerRemovalKeepsFirstAndThirdSlots(testCase)
    setup_paths();
    glob = syntheticGlobalMatrices();
    fem = struct();
    fem.ElemType = [1, 1, 3, 1, 3];
    fem.Element = [1, 1, 0, 1];
    fem.Node = zeros(1, 12);
    mateProp = {struct('IsSmtLay', 2); struct('IsSmtLay', 2); struct('IsSmtLay', 2)};

    condensed = SF_Condensation(glob, fem, mateProp);
    keep = [1, 3];

    verifyEqual(testCase, condensed.KffMT, glob.KffMT(keep, keep));
    verifyEqual(testCase, condensed.KzzT, glob.KzzT(keep, keep));
    verifyEqual(testCase, condensed.KttT, glob.KttT(keep, keep));
    verifyEqual(testCase, condensed.KftT, glob.KftT(keep, keep));
    verifyEqual(testCase, condensed.KtfT, glob.KtfT(keep, keep));
    verifyEqual(testCase, condensed.KztT, glob.KztT(keep, keep));
    verifyEqual(testCase, condensed.KtzT, glob.KtzT(keep, keep));
    verifyEqual(testCase, condensed.KufMT, glob.KufMT(:, keep));
    verifyEqual(testCase, condensed.KfuMT, glob.KfuMT(keep, :));
    verifyEqual(testCase, condensed.KutT, glob.KutT(:, keep));
    verifyEqual(testCase, condensed.KtuT, glob.KtuT(keep, :));
end

function glob = syntheticGlobalMatrices()
    glob = struct();
    glob.MuuT = 1;
    glob.CuuT = 2;
    glob.KuuT = 3;
    glob.KufMT = [11, 12, 13];
    glob.KfuMT = [21; 22; 23];
    glob.KffMT = diag([31, 32, 33]);
    glob.KutT = [41, 42, 43];
    glob.KtuT = [51; 52; 53];
    glob.KftT = diag([61, 62, 63]);
    glob.KtfT = diag([71, 72, 73]);
    glob.KztT = diag([81, 82, 83]);
    glob.KtzT = diag([91, 92, 93]);
    glob.KttT = diag([101, 102, 103]);
    glob.KuzT = [111, 112, 113];
    glob.KzuT = [121; 122; 123];
    glob.KfzT = diag([131, 132, 133]);
    glob.KzfT = diag([141, 142, 143]);
    glob.KzzT = diag([151, 152, 153]);
    glob.FuiT = 201;
    glob.FusT = 202;
    glob.FucT = 203;
    glob.GfiMT = [211; 212; 213];
    glob.GfMT = [221; 222; 223];
    glob.MziT = [231; 232; 233];
    glob.MzT = [241; 242; 243];
    glob.FtT = [251; 252; 253];
end
